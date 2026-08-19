# Audits every view for design system conformance, by page kind.
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
# Usage: ruby bin/design/page-audit.rb [show|index|form|partial]
#        Exits non-zero if any DEFECT is found. DEBT is reported, not enforced.
AUTH = %w[users/sessions users/passwords users/confirmations users/unlocks
  users/invitations users/registrations account_requests].freeze

# Classes nothing defines. `text-bold` is the one that bites: the author meant `font-bold`.
UNDEFINED = %w[text-bold text-italic form-horizontal form-group control-label help-block
  collapsed-card card-body].freeze

# `card` on its own is the Bootstrap/AdminLTE card and is defined nowhere now, so an element
# carrying it has no border, background or shadow. Matched with word boundaries inside a class
# attribute so `card-body`, `content-card` and `data-card` do not trip it.
BARE_CARD = /class="[^"]*\bcard\b[^"]*"/

DS_H1 = "text-2xl font-bold tracking-tight text-slate-900"
CARD_CLASSES = "rounded-2xl border border-slate-200 bg-white shadow-sm"
LTE_COMMENT = /<!--\s*(left column|right column|jquery validation|form start|Default box|\/?\.[\w-]+)\s*-->/

KINDS = {
  "show" => %r{/show\.html\.erb$},
  "index" => %r{/index\.html\.erb$},
  "form" => %r{/(new|edit)\.html\.erb$|/_form\.html\.erb$},
  "partial" => %r{/_[^/]+\.html\.erb$}
}.freeze

def strip_comments(src) = src.gsub(/<%#.*?%>/m, "")

scope = ARGV.first
kinds = scope ? {scope => KINDS.fetch(scope)} : KINDS

rows = []
kinds.each do |kind, pattern|
  Dir.glob("app/views/**/*.html.erb").sort.each do |file|
    rel = file.sub("app/views/", "")
    next unless rel.match?(pattern)
    # The design system's own components are the definition, not a copy of it.
    next if rel.start_with?("shared/essentials/")
    # A form partial is audited as a form, not twice.
    next if kind == "partial" && rel.match?(KINDS["form"])
    # Mailer templates are styled for email clients, where inline style is the only option.
    next if rel.include?("_mailer/") || rel.start_with?("layouts/mailer")
    # The marketing pages are standalone public documents on their own stylesheet, deliberately
    # outside the design system -- see docs/migration-map.md.
    next if rel.start_with?("static/")

    raw = File.read(file)
    src = strip_comments(raw)
    auth = AUTH.any? { |prefix| rel.start_with?(prefix) }

    defects = []
    dead = UNDEFINED.select { |c| src.include?(c) }
    dead << "card" if src.match?(BARE_CARD)
    defects << "dead class: #{dead.join(", ")}" if dead.any?
    inline = src.scan(/style=['"]/).size
    defects << "#{inline} inline style#{"s" if inline > 1}" if inline.positive?
    # &nbsp; inside sr-only prose separates words for a screen reader; without it "Deactivate"
    # runs into the explanation after it. Only layout &nbsp; is a defect.
    nbsp = src.gsub(/<span class="sr-only">.*?<\/span>/m, "").scan("&nbsp;").size
    defects << "#{nbsp} &nbsp;" if nbsp.positive?
    title_case = src.scan(/<h[1-3][^>]*>\s*([A-Z][a-z]+(?: [A-Z][a-z]+){1,})/).flatten.uniq
    defects << "Title Case: #{title_case.first}" if title_case.any?
    if %w[show index form].include?(kind) && src.match?(/<h1[^>]*>/) &&
        !src.include?("shared/essentials/page_header") && !(auth && src.include?(DS_H1))
      defects << "no page_header"
    end

    debt = []
    debt << "hand-rolled card" if src.include?(CARD_CLASSES) && !src.include?("shared/essentials/card")
    comments = raw.scan(LTE_COMMENT).size
    debt << "#{comments} AdminLTE comment#{"s" if comments > 1}" if comments.positive?

    rows << [kind, rel, defects, debt] if defects.any? || debt.any?
  end
end

%w[show index form partial].each do |kind|
  next unless kinds.key?(kind)
  of_kind = rows.select { |r| r[0] == kind }
  total = Dir.glob("app/views/**/*.html.erb").count { |f|
    rel = f.sub("app/views/", "")
    rel.match?(KINDS[kind]) && !rel.start_with?("shared/essentials/") &&
      !rel.include?("_mailer/") && !(kind == "partial" && rel.match?(KINDS["form"]))
  }
  defects = of_kind.reject { |r| r[2].empty? }
  puts "== #{kind} (#{total} files, #{defects.size} with defects, #{of_kind.size - defects.size} debt only)"
  of_kind.each do |_, rel, d, t|
    marker = d.any? ? "DEFECT" : "  debt"
    puts format("  %s  %-52s %s", marker, rel, (d + t).join("; "))
  end
  puts
end

defect_count = rows.count { |r| r[2].any? }
puts "#{defect_count} files with defects, #{rows.size - defect_count} with debt only"
exit(defect_count.zero? ? 0 : 1)
