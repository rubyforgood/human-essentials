# Finds pages whose *shell* was migrated and whose *body* was not.
#
# Every other audit in this directory asks: is anything from the old system still present? A
# shell-first page passes all of them. `/organization` did: HTTP 200, no Bootstrap class, no Font
# Awesome icon, no console error, a proper page header and a proper card -- and inside the card,
# 28 fields as flat `<p>` pairs, six `<hr>` drawn in slate-900, seven different vertical gaps and
# an icon on fourteen rows. Nothing the app could run knew the difference.
#
# So this one asks the other question: is this built the way the new system builds things?
#
# It reads templates. No browser, no server, no database.
#
# Usage: ruby bin/design/shell-first-audit.rb
#        Exits non-zero if anything is found.

ROOT = File.expand_path("../..", __dir__)
VIEWS = File.join(ROOT, "app/views")

# Not app pages, and every finding in them would be wrong.
#
# Mailers are HTML email, where a table *is* the layout tool and inline style is the only thing
# that survives Outlook. Devise puts its own under `users/mailer/`, and `layouts/mailer.html.erb`
# is the mailer layout -- neither of which a `*_mailer/` directory pattern catches.
#
# `static/` is the legal pages, which `StaticController` renders with `layout false`: complete
# HTML documents carrying their own `<style>`. They are not built from this design system and
# were never meant to be.
SKIP = %r{/(\w+_mailer|users/mailer|kaminari|static)/|/layouts/mailer\.}

# ERB comments are prose about the markup, and prose talks about the very patterns being looked
# for -- these files are full of sentences like "was `float-right`". Both comment forms have to
# go: `<%# ... %>` and a `#` line inside a `<% ... %>` block.
def strip_comments(src)
  src = src.gsub(/<%#.*?%>/m, "")
  src.gsub(/<%[=-]?(.*?)-?%>/m) do
    body = Regexp.last_match(1)
    "<%" + body.lines.reject { |l| l.strip.start_with?("#") }.join + "%>"
  end
end

# A table that is not `.data-table` has no header rule, no zebra, no frozen first column and no
# scroll rail -- it is the browser's default table on a page where every other table is the
# design system's.
def legacy_table(src)
  src.scan(/<table\b[^>]*>/).reject { |t| t.include?("data-table") }
end

# Preflight sets `border-color: currentColor`, so an `<hr>` with no border class draws in the
# *text* colour -- near-black, against the slate-200 hairline every other divider uses.
def bare_hr(src)
  src.scan(/<hr\b[^>]*>/).reject { |t| t =~ /class="[^"]*\bborder-/ }
end

def floats(src)
  src.scan(/\bfloat-(?:left|right|start|end)\b/)
end

# `<br>` between two lines of text is correct HTML -- an address, a second line in a table cell --
# and 29 of the 31 the unnarrowed version reported were exactly that. Only two shapes are layout
# standing in for a margin: a doubled `<br>`, and one immediately after a block element closes.
def layout_br(src)
  src.scan(%r{<br\s*/?>\s*<br\s*/?>|</(?:p|div|h[1-6]|ul|ol|table|section)>\s*<br\s*/?>}i)
end

# A label above a value is a description list. Written as `<p>` pairs it has no semantics, and it
# is the single clearest marker of a body that was never migrated: `/organization` had 28.
#
# Threshold of four, because `text-xs text-slate-500` on its own is the documented *meta* style --
# a timestamp under a heading, a hint under a field -- and one or two of those is a page using the
# design system correctly, not a description list in disguise.
#
# `font-medium` is required as well, and it is the whole discriminator. It is what `essentials_detail`
# puts on a `<dt>`, so it marks a *label above a value*. Without it the check also matched a stat
# card's caption *below* a number -- small, grey, four of them in a row on the partner dashboard,
# and correct.
DETAIL_PAIR = /<p[^>]*class="[^"]*text-(?:xs|sm)[^"]*font-medium[^"]*text-slate-(?:500|600)[^"]*"[^>]*>/

def flat_detail_pairs(src)
  found = src.scan(DETAIL_PAIR)
  (found.size >= 4) ? found : []
end

# The card component draws its own header from `title:`. Written by hand it drifts -- and this is
# how a hand-rolled card header hides inside a legitimately-rendered card: `admin/users/_roles`
# rendered the card properly and then wrote the header out underneath it.
#
# A modal's header is not a card's and looks identical -- hairline rule, heading, close button.
# So the check requires a card to actually be present in the file: a hand-written *card* header
# is by definition a header for a card, and `_roles` is the shape it looks for, rendering the
# component and then writing the header out underneath it.
#
# Matching the markup alone reported all fourteen modals in the app and every one was fine --
# including three whose `<dialog>` is in `confirmation_controller.js` rather than in the template,
# so no amount of looking for `<dialog>` in the file would have excluded them.
def handrolled_card_header(src)
  return [] unless %r{shared/essentials/card|\bcard-surface\b}.match?(src)

  src.scan(%r{<div[^>]*class="[^"]*border-b[^"]*"[^>]*>\s*<h[23][^>]*>}m)
end

# A button's classes copied out instead of asked for. `essentials_button_classes` is the one
# place the sizes, focus ring and disabled state are defined; a copy is a button that stops
# matching the moment any of them changes, and the copies in this app had already drifted --
# the filter bar's toggle was `font-semibold` with a `shadow-sm` against the helper's plain
# `font-medium`.
#
# The padding utility is required, and it is what separates a copied button from an icon-only
# chrome control. The hamburger, the kebab and the segmented-toggle shell are all
# `inline-flex rounded-lg` with a `size-*` and no padding at all; they are not buttons the helper
# has ever produced, so calling them copies of it was wrong.
RAW_BUTTON = /class(?::| *=) *"[^"]*\binline-flex\b[^"]*\brounded-lg\b[^"]*\bpx-[\d.]+[^"]*"/

def raw_button_string(src)
  src.scan(RAW_BUTTON).reject { |m| m.include?("essentials_button_classes") }
end

def fa_icons(src)
  src.scan(/\bfa-[a-z0-9-]+/)
end

# Two page gutters in one template: the wrapper closed after the page header and a second one
# opened for the content, so the first one's bottom padding stacks on the second one's top and the
# gap under the heading becomes 48 or 72 where the design system's is 24.
#
# Matched on the *gutter* -- `px-4 sm:px-6 lg:px-8` -- and not on the whole `px-4 py-6 sm:px-6
# lg:px-8` string, which is how the first version of this check missed 17 of them: they open with
# `pt-6` rather than `py-6`, and comparing the full class string made two wrappers look like one
# wrapper and something else.
PAGE_GUTTER = /<div[^>]*class="[^"]*\bpx-4\b[^"]*\bsm:px-6\b[^"]*\blg:px-8\b[^"]*"/

def double_page_wrapper(src)
  hits = src.scan(PAGE_GUTTER)
  (hits.size >= 2) ? hits : []
end

CHECKS = {
  "table is not .data-table" => method(:legacy_table),
  "bare <hr> (draws in slate-900)" => method(:bare_hr),
  "float-* for layout" => method(:floats),
  "<br> standing in for a margin" => method(:layout_br),
  "4+ flat <p> label pairs (should be a <dl>)" => method(:flat_detail_pairs),
  "hand-written card header" => method(:handrolled_card_header),
  "button classes pasted inline" => method(:raw_button_string),
  "Font Awesome icon" => method(:fa_icons),
  "two page gutters (48-72px under the heading)" => method(:double_page_wrapper)
}.freeze

# The detectors are proved before anything is reported. A check that silently matches nothing
# reports a clean sweep, which is the failure mode that looks like success -- and three of these
# were narrowed *after* they produced false positives, so the narrowing itself needs pinning.
PROBES = [
  ['<table class="table border">', :legacy_table, true],
  ['<table class="data-table">', :legacy_table, false],
  ["<hr>", :bare_hr, true],
  ['<hr class="my-4 border-slate-200">', :bare_hr, false],
  ['<div class="float-right">', :floats, true],
  ["<br><br>", :layout_br, true],
  ["</p>\n<br>", :layout_br, true],
  # Correct HTML, and the reason this check is not simply /<br>/: 29 of the 31 the first version
  # reported were one of these two.
  ["<address>1 Main St<br>Springfield</address>", :layout_br, false],
  ["<td>Jo Smith<br>jo@example.com</td>", :layout_br, false],
  [('<p class="text-xs font-medium text-slate-500">L</p><p>v</p>' * 4), :flat_detail_pairs, true],
  # One or two is the meta style: a timestamp under a heading. Not a description list.
  [('<p class="text-xs font-medium text-slate-500">Updated today</p>' * 2), :flat_detail_pairs, false],
  # A stat card's caption, four in a row, correct. No `font-medium`, because it labels the number
  # above it rather than the value below it.
  [('<p class="text-sm text-slate-600">Families served</p>' * 4), :flat_detail_pairs, false],
  [%(<%= render "shared/essentials/card" do %><div class="border-b border-slate-200 px-5 py-4">
<h2 class="font-semibold">Users</h2>), :handrolled_card_header, true],
  [%(<div class="card-surface"><div class="border-b border-slate-200 px-5"><h3>x</h3>),
    :handrolled_card_header, true],
  # A modal's header. Same markup exactly, and not a card -- there is no card in the file.
  [%(<div class="flex items-start justify-between border-b border-slate-200 px-5 py-4">
<h2>Confirm this transfer</h2>), :handrolled_card_header, false],
  ['class: "inline-flex items-center rounded-lg bg-brand-600 px-3.5 py-2"', :raw_button_string, true],
  ['class="inline-flex items-center rounded-lg border border-slate-300 px-2.5 py-1.5"', :raw_button_string, true],
  ["class: essentials_button_classes(:primary)", :raw_button_string, false],
  # An icon-only chrome control: sized, not padded. The helper has never produced one.
  ['class="inline-flex size-11 items-center justify-center rounded-lg text-slate-500"', :raw_button_string, false],
  ['<i class="fa fa-plus"></i>', :fa_icons, true],
  ['<i class="bi bi-plus"></i>', :fa_icons, false],
  [%(<div class="px-4 py-6 sm:px-6 lg:px-8">a</div><div class="px-4 py-6 sm:px-6 lg:px-8">b</div>),
    :double_page_wrapper, true],
  # The variant the first version missed: the header wrapper opens `pt-6`, the content one `py-6`.
  [%(<div class="px-4 pt-6 sm:px-6 lg:px-8">a</div><div class="max-w-3xl px-4 py-6 sm:px-6 lg:px-8">b</div>),
    :double_page_wrapper, true],
  [%(<div class="px-4 py-6 sm:px-6 lg:px-8"><div class="space-y-6">a</div></div>),
    :double_page_wrapper, false]
].freeze

PROBES.each do |markup, check, expected|
  got = send(check, markup).any?
  next if got == expected

  abort "#{check} detector is wrong: #{markup.inspect} => #{got}, expected #{expected}.\n" \
        "Fix it before trusting any result below."
end

findings = Hash.new { |h, k| h[k] = [] }
scanned = 0

Dir.glob(File.join(VIEWS, "**/*.erb")).sort.each do |path|
  rel = path.sub("#{ROOT}/", "")
  next if SKIP.match?(rel)

  scanned += 1
  src = strip_comments(File.read(path))

  CHECKS.each do |label, check|
    hits = check.call(src)
    findings[rel] << [label, hits.size] if hits.any?
  end
end

puts "Scanned #{scanned} templates.\n\n"

if findings.empty?
  puts "No shell-first symptoms found."
  exit 0
end

findings.sort.each do |rel, hits|
  puts rel
  hits.each { |label, n| puts format("  %-45s %d", label, n) }
end

puts "\n#{findings.size} template(s) with a body that does not match the shell around it."
exit 1
