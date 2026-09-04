# Audits every view for design system conformance, by page kind.
require "set"
#
# `status.rb` asks whether a view contains design system markup. Every page here does, which is
# why it reports them all as migrated. The layout is not the page: a view can sit in the right
# shell and still build its own header, its own card and its own inputs.
#
# Two severities, because they are not the same problem:
#
#   DEFECT   The page is wrong now -- a class nothing defines, a hardcoded inline style, layout
#            built from &nbsp;, Title Case where the house style is sentence case, or a page with
#            no page_header and therefore no back link.
#
#   DEBT     The page renders correctly but has the card's classes pasted inline instead of
#            rendering the component, so a change to the card will never reach it.
#
# Usage: ruby bin/design/page-audit.rb [show|index|form|partial|action]
#        Exits non-zero if any DEFECT is found. DEBT is reported, not enforced.
AUTH = %w[users/sessions users/passwords users/confirmations users/unlocks
  users/invitations users/registrations account_requests].freeze

# Classes nothing defines. `text-bold` is the one that bites: the author meant `font-bold`.
# Capitalised runs that are names rather than Title Case. The audit cannot infer these, and a
# heading naming the product is not a style violation.
PROPER_NOUNS = ["Human Essentials", "Code for GoodOps", "Ruby for Good"].freeze

# Capitalised runs inside a *label* that are names, not Title Case. Ethnicity and nationality
# terms are proper adjectives and keep their capitals in sentence case exactly as a place name
# does; `Form 990` is the name of an IRS form. Without this list the population-served fields
# would be reported forever and the check would be the kind people learn to ignore.
LABEL_PROPER_NOUNS = ["African American", "American Indian", "Pacific Island", "Native Hawaiian",
  "Alaska Native", "Middle Eastern", "Form 990"].freeze

UNDEFINED = %w[text-bold text-italic form-horizontal form-group control-label help-block
  collapsed-card card-body].freeze

# `card` on its own is the Bootstrap/AdminLTE card and is defined nowhere now, so an element
# carrying it has no border, background or shadow.
#
# Split into class tokens rather than matched with `\bcard\b`, which was never as narrow as its
# comment claimed: `-` is a non-word character, so that pattern matches inside `card-surface`,
# `content-card` and `data-card` too. It went unnoticed while nothing legitimate contained the
# substring; adding `.card-surface` made every card in the app report as a dead Bootstrap class.
def bare_card?(src)
  src.scan(/class="([^"]*)"/).flatten.any? { |attr| attr.split(/\s+/).include?("card") }
end

[
  ['<div class="card">', true],
  ['<div class="card mb-3">', true],
  ['<div class="card-surface overflow-hidden">', false],
  ['<div class="content-card">', false],
  ['<div data-card="1" class="p-4">', false]
].each do |markup, expected|
  next if bare_card?(markup) == expected

  abort "bare-card detector is wrong: #{markup.inspect} => #{!expected}, expected #{expected}."
end

DS_H1 = "text-2xl font-bold tracking-tight text-slate-900"

# A card is a *surface*, not a string: white, hairline border, `rounded-2xl`, `shadow-sm`
# (design.md). So the check is for those tokens together inside one `class` attribute, not for
# the exact `rounded-2xl border border-slate-200 bg-white shadow-sm` substring it used to be.
#
# The substring version caught 0 of the 4 hand-rolled cards in the app. One padding utility
# between `bg-white` and `shadow-sm` is enough to slip past it, and three of the four do exactly
# that -- `bg-white p-4 shadow-sm`. All four tokens have to be in the *same* attribute, so a
# rounded div wrapping a white one is not a card.
CARD_TOKENS = %w[rounded-2xl border-slate-200 bg-white shadow-sm].freeze

def hand_rolled_card?(src)
  src.scan(/class="([^"]*)"/).flatten.any? do |attr|
    names = attr.split(/\s+/)
    CARD_TOKENS.all? { |token| names.include?(token) }
  end
end

# An icon tile hand-rolled instead of calling `essentials_icon_tile`: a tone-coloured, fixed-size
# rounded box. `rounded-full` is excluded, and that is the whole discriminator -- a circle is an
# avatar or a numbered badge, which design.md keeps deliberately disjoint from tiles. The reports
# hub had built its own at 28px/`rounded-lg`/`text-brand-700` against the helper's
# 36px/`rounded-xl`/`text-brand-600`, so three properties had drifted rather than one.
TILE_TONES = %w[bg-brand-50 bg-sky-50 bg-emerald-50 bg-amber-50 bg-rose-50 bg-slate-100].freeze

def hand_rolled_tile?(src)
  src.scan(/class="([^"]*)"/).flatten.any? do |attr|
    names = attr.split(/\s+/)
    names.any? { |n| n.start_with?("rounded") } && !names.include?("rounded-full") &&
      TILE_TONES.any? { |t| names.include?(t) } &&
      names.any? { |n| n.match?(/\A(size-\d+|h-\d+)\z/) }
  end
end

[
  ['<span class="flex size-7 shrink-0 rounded-lg bg-brand-50 text-brand-700">', true],
  ['<span class="grid h-9 w-9 place-items-center rounded-xl bg-amber-50">', true],
  ['<span class="grid h-8 w-8 place-items-center rounded-full bg-brand-100">', false], # avatar
  ['<span class="grid h-5 w-5 place-items-center rounded-full bg-brand-100">', false], # step badge
  ['<div class="rounded-lg bg-brand-50 p-4">', false]                                  # no fixed size
].each do |markup, expected|
  next if hand_rolled_tile?(markup) == expected

  abort "tile detector is wrong: #{markup.inspect} => #{!expected}, expected #{expected}."
end

# Same idea as `undefined-classes.py`: prove the detector before trusting a run of it. The last
# two versions of this check were each wrong in a way that reported zero, which is the failure
# mode that looks like success.
[
  ['<div class="rounded-2xl border border-slate-200 bg-white shadow-sm">', true],   # the canonical order
  ['<div class="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">', true], # padding interleaved
  ['<div class="flex gap-3 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">', true],
  ['<div class="bg-white shadow-sm border border-slate-200 rounded-2xl">', true],   # reordered
  ['<div class="rounded-2xl bg-white">', false],                                    # not a card
  ['<div class="rounded-2xl border-slate-200"><p class="bg-white shadow-sm">', false], # split across two
  ['<div class="card-surface overflow-hidden">', false],                            # the class, not a paste
  ['<div class="card-surface flex items-center gap-3 p-5">', false]
].each do |markup, expected|
  next if hand_rolled_card?(markup) == expected

  abort "card detector is wrong: #{markup.inspect} => #{!expected}, expected #{expected}. " \
        "Fix it before trusting any result below."
end

LTE_COMMENT = /<!--\s*(left column|right column|jquery validation|form start|Default box|\/?\.[\w-]+)\s*-->/

# The four RESTful shapes, and then everything else. "action" is the catch-all, and it exists
# because the first four are not exhaustive: a controller may render a template named after a
# collection action -- items/inventory, items/quantity_and_location -- and for as long as the
# list stopped at `partial` those templates matched nothing and were audited by nothing. Any
# view is one of these five, so a new page cannot fall out of the audit by being named oddly.
KINDS = {
  "show" => %r{/show\.html\.erb$},
  "index" => %r{/index\.html\.erb$},
  "form" => %r{/(new|edit)\.html\.erb$|/_form\.html\.erb$},
  "partial" => %r{/_[^/]+\.html\.erb$},
  "action" => %r{\A(?!.*/_)(?!.*/(show|index|new|edit)\.html\.erb$).*\.html\.erb$}
}.freeze

def strip_comments(src) = src.gsub(/<%#.*?%>/m, "")

# The one place the exclusions live. They used to be written twice -- once as `next if` guards in
# the scan and once, less completely, in the per-kind total -- so the totals counted files the
# audit had skipped and every "N files" line was slightly too big.
# Inline `style` attributes that declare presentation, which is the thing the rule is against.
#
# The check used to be `src.scan(/style=['"]/)`, which is broader than the sentence above it: it
# counted every style attribute, including the two that carry a **value rather than a declaration**
# -- a share bar's length and a chart box's reserved height. Neither can be a class. Both are
# continuous numbers the server computes, and Tailwind only compiles the classes it can see in the
# source, so `w-[37.2%]` interpolated at runtime is a class that does not exist.
#
# The line is drawn at the **custom property**. `style="--share-fill: 37.2%"` cannot style anything
# on its own: some rule in the stylesheet has to pick it up and use it, so every declaration stays
# in CSS and the markup carries only data. `style="width: 37.2%"` is a declaration in the markup and
# is still a defect, interpolated or not.
#
# Deliberately *not* "does it contain ERB": that would let `style="<%= "color: red" %>"` through,
# and would make the rule about how a string was built rather than about what it does.
def presentational_styles(src)
  src.scan(/style=(['"])(.*?)\1/m).count do |_quote, value|
    # An empty attribute declares nothing; anything else must be custom properties throughout.
    value.split(";").map(&:strip).reject(&:empty?).any? { |decl| !decl.start_with?("--") }
  end
end

def audited?(rel, kind)
  return false unless rel.match?(KINDS[kind])
  return false if rel.start_with?("shared/essentials/")
  return false if kind == "partial" && rel.match?(KINDS["form"])
  return false if rel.include?("_mailer/") || rel.include?("/mailer/") || rel.start_with?("layouts/mailer")
  return false if rel.start_with?("static/")

  true
end

scope = ARGV.first
kinds = scope ? {scope => KINDS.fetch(scope)} : KINDS

rows = []
kinds.each do |kind, pattern|
  Dir.glob("app/views/**/*.html.erb").sort.each do |file|
    rel = file.sub("app/views/", "")
    # Excluded, and why:
    #   shared/essentials/  the design system's own components are the definition, not a copy
    #   form partials       audited as a form, not twice
    #   mailers             styled for email clients, where inline style is the only option
    #   static/             standalone public documents on their own stylesheet, see migration-map
    next unless audited?(rel, kind)

    raw = File.read(file)
    src = strip_comments(raw)
    auth = AUTH.any? { |prefix| rel.start_with?(prefix) }

    defects = []
    dead = UNDEFINED.select { |c| src.include?(c) }
    dead << "card" if bare_card?(src)
    defects << "dead class: #{dead.join(", ")}" if dead.any?
    inline = presentational_styles(src)
    defects << "#{inline} inline style#{"s" if inline > 1}" if inline.positive?
    # &nbsp; inside sr-only prose separates words for a screen reader; without it "Deactivate"
    # runs into the explanation after it. Only layout &nbsp; is a defect.
    nbsp = src.gsub(/<span class="sr-only">.*?<\/span>/m, "").scan("&nbsp;").size
    defects << "#{nbsp} &nbsp;" if nbsp.positive?
    # A proper noun is not Title Case, and the check could not tell the difference: "Contact Human
    # Essentials" was reported the moment that heading was written. Same idea as `copy-audit`'s
    # ACRONYMS list -- the audit has to be told which capitalised runs are real names.
    # Inner tags are stripped rather than terminating the capture: `<h3><strong>Race/Ethnicity of
    # Client Base</strong></h3>` is a heading whose text the old scan could not reach at all.
    heading_text = src.scan(%r{<h[1-3][^>]*>(.{2,120}?)</h[1-3]>}m).flatten
      .map { |t| t.gsub(/<[^>]+>/, " ").gsub(/\s+/, " ").strip }
      .map { |t| PROPER_NOUNS.reduce(t) { |acc, n| acc.gsub(n, "") } }
    title_case = heading_text.filter_map { |t| t[/[A-Z][a-z]+(?: [A-Z][a-z]+){1,}/] }.uniq
    defects << "Title Case: #{title_case.first}" if title_case.any?
    #
    # **Labels too, not only headings.** design.md asks for sentence case on "headings, buttons,
    # labels, table headers, nav items, flash messages, empty states", and this check covered the
    # first of those -- so 30 Title Case labels sat on the partner profile forms for the whole
    # migration without ever being reported. A rule with no audit is a suggestion.
    #
    # The test is a capitalised word that is *not* the first word of the label: `Agency Age` fails,
    # `Agency age` passes. Acronyms are left alone (`FPL`, `ZIP`) because an all-caps token is not
    # Title Case, and the proper nouns above are removed before looking.
    # A hand-written brand link. `.link-brand` carries the colour *and* the underline on hover and
    # focus, which is the part that matters: measured against the prose these sit in, the brand
    # colour is 1.04:1 on slate-600, so colour alone marks nothing. 71 of these existed in 13
    # different shapes before the class did; the pair is the signature.
    if src.include?("hover:text-brand-800")
      defects << "hand-written brand link (use .link-brand)"
    end
    labels = src.scan(/label:\s*"([^"]{3,120})"/).flatten
      .map { |t| LABEL_PROPER_NOUNS.reduce(t) { |acc, n| acc.gsub(n, "") } }
    title_case_labels = labels.filter_map { |t|
      words = t.scan(/[A-Za-z][A-Za-z']*/)
      next if words.size < 2
      t if words.drop(1).any? { |w| w[0] == w[0].upcase && w != w.upcase }
    }.uniq
    if title_case_labels.any?
      defects << "Title Case label: #{title_case_labels.first} (#{title_case_labels.size})"
    end
    if %w[show index form].include?(kind) && src.match?(/<h1[^>]*>/) &&
        !src.include?("shared/essentials/page_header") && !(auth && src.include?(DS_H1))
      defects << "no page_header"
    end

    debt = []
    comments = raw.scan(LTE_COMMENT).size
    debt << "#{comments} AdminLTE comment#{"s" if comments > 1}" if comments.positive?

    rows << [kind, rel, defects, debt] if defects.any? || debt.any?
  end
end

%w[show index form partial action].each do |kind|
  next unless kinds.key?(kind)
  of_kind = rows.select { |r| r[0] == kind }
  total = Dir.glob("app/views/**/*.html.erb").count { |f| audited?(f.sub("app/views/", ""), kind) }
  defects = of_kind.reject { |r| r[2].empty? }
  puts "== #{kind} (#{total} files, #{defects.size} with defects, #{of_kind.size - defects.size} debt only)"
  of_kind.each do |_, rel, d, t|
    marker = d.any? ? "DEFECT" : "  debt"
    puts format("  %s  %-52s %s", marker, rel, (d + t).join("; "))
  end
  puts
end

# Two checks that ask "did someone rebuild a thing the design system already defines?", run
# across everything that emits markup rather than per page kind. Both had to be global: the
# copies they were written for hid in a helper (`essentials_stats`) and in `shared/essentials/`
# (`_disclosure`), and the per-kind scan reaches neither -- it globs views only, and skips the
# design system's own partials as "the definition, not a copy". That skip made sense while a
# component's markup was the definition. It is a CSS class and a helper now, so the components
# are callers like everybody else.
EMITS_MARKUP = Dir.glob("{app/views/**/*.html.erb,app/helpers/**/*.rb,app/javascript/**/*.js,app/components/**/*}")
  .select { |f| File.file?(f) }
  .reject { |f| f.include?("_mailer/") || f.include?("/mailer/") || f.start_with?("app/views/static/") }
  .to_h { |f| [f, File.read(f, encoding: "UTF-8", invalid: :replace, undef: :replace, replace: "")] }

# The helper defines the tile, so it is not a copy of itself.
TILE_DEFINITION = "app/helpers/essentials_ui_helper.rb"

GLOBAL_DEBT = {
  "card surface pasted instead of .card-surface" =>
    EMITS_MARKUP.select { |_f, src| hand_rolled_card?(src) }.keys,
  "icon tile hand-rolled instead of essentials_icon_tile" =>
    EMITS_MARKUP.reject { |f, _| f == TILE_DEFINITION }.select { |_f, src| hand_rolled_tile?(src) }.keys
}.reject { |_label, files| files.empty? }

GLOBAL_DEBT.each do |label, files|
  puts "== #{label} (#{files.size})"
  files.sort.each { |f| puts format("    debt  %s", f) }
  puts
end

# Links inside the documentation that point at a heading nobody wrote, or wrote and then renamed.
#
# **Seven of these accumulated during the migration**, and every one turned out to be a section that
# had been renamed rather than one that never existed -- `#target-size` had become "Tap targets",
# `#pills` "Status pills" -- plus two written as bare fragments while pointing at a heading in
# `docs/onboarding.md`. A cross-reference that silently goes nowhere is worse than no cross-reference,
# because the reader assumes the explanation exists and cannot find it.
#
# Checked here rather than in a browser audit because it is a fact about the source, and because the
# documents are the thing this whole suite exists to keep honest.
DOCS = ["design.md", *Dir["docs/*.md"]].select { |f| File.exist?(f) }

def slugs_in(path)
  text = File.read(path)
  ids = text.scan(/<a id="([^"]+)"/).flatten
  # `1,6` and not `2,6`: onboarding.md's two part dividers are h1, and excluding them
  # reported its own table of contents as broken. A false positive in the checker, caught by
  # reading what it accused rather than trusting the count.
  headings = text.scan(/^\#{1,6}\s+(.+)$/).flatten
    .map { |h| h.downcase.gsub(/[^a-z0-9 -]/, "").tr(" ", "-") }
  (ids + headings).to_set
end

SLUGS = DOCS.to_h { |f| [f, slugs_in(f)] }
dead_links = DOCS.flat_map { |f|
  text = File.read(f)
  same = text.scan(/\]\(#([a-z0-9-]+)\)/).flatten.reject { |a| SLUGS[f].include?(a) }
    .map { |a| "#{f}: ##{a}" }
  # **Resolved against the file holding the link, not the working directory.** The first version
  # looked up `../design.md` as written, found no entry, fell through to `!File.exist?` -- which is
  # false for a path relative to the wrong directory -- and treated "cannot find the file" as
  # "fine". It passed `docs/design-decisions.md: ../design.md#target-size` while that anchor was
  # being renamed out from under it. A link the checker cannot resolve is a defect, not a skip.
  cross = text.scan(%r{\]\(([\w./-]+\.md)#([a-z0-9-]+)\)}).reject { |target, frag|
    resolved = File.expand_path(target, File.dirname(f)).delete_prefix("#{Dir.pwd}/")
    SLUGS[resolved]&.include?(frag)
  }.map { |target, frag| "#{f}: #{target}##{frag}" }
  same + cross
}.uniq

unless dead_links.empty?
  puts "== documentation links pointing at a heading that does not exist (#{dead_links.size})"
  dead_links.sort.each { |l| puts format("    DEFECT  %s", l) }
  puts
end

defect_count = rows.count { |r| r[2].any? }
debt_count = (rows.size - defect_count) + GLOBAL_DEBT.values.sum(&:size)
# Dead links are defects, but they are not *files*, so they are counted separately and only added
# to the headline -- folding them into `defect_count` made the debt figure go negative.
defect_count += dead_links.size
puts "#{defect_count} files with defects, #{debt_count} with debt only"
exit(defect_count.zero? ? 0 : 1)
