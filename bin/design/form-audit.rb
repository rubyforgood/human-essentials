# Audits new/edit/form views for design system conformance.
#
# These pages render on a design system layout, so status.rb counts them as migrated. The layout
# is not the page: a view can sit in the right shell and still build its own header, its own card
# and its own inputs. That is what this looks for.
#
# Devise views are judged against the auth layout, which has no page header bar, so a plain <h1>
# carrying the design system's classes is correct there.
AUTH = %w[users/sessions users/passwords users/confirmations users/unlocks
  users/invitations users/registrations account_requests].freeze

# Classes nothing defines. `text-bold` is the interesting one: the author meant `font-bold`.
UNDEFINED = %w[text-bold form-horizontal form-group control-label help-block].freeze

DS_H1 = "text-2xl font-bold tracking-tight text-slate-900"
LTE_COMMENT = /<!--\s*(left column|right column|jquery validation|form start|\/?\.[\w-]+)\s*-->/

files = Dir.glob("app/views/**/*.html.erb")
  .select { |f| f.match?(%r{/(new|edit)\.html\.erb$|/_form\.html\.erb$}) }
  .sort

findings = files.filter_map do |file|
  rel = file.sub("app/views/", "")
  src = File.read(file)
  auth = AUTH.any? { |prefix| rel.start_with?(prefix) }

  issues = []
  dead = UNDEFINED.select { |c| src.include?(c) }
  issues << "dead class: #{dead.join(", ")}" if dead.any?
  if src.match?(/<h1[^>]*>/) && !src.include?("shared/essentials/page_header") && !(auth && src.include?(DS_H1))
    issues << "no page_header"
  end
  if src.match?(/rounded-2xl border border-slate-200 bg-white shadow-sm/) && !src.include?("shared/essentials/card")
    issues << "hand-rolled card"
  end
  comments = src.scan(LTE_COMMENT).size
  issues << "#{comments} AdminLTE comment(s)" if comments.positive?
  title_case = src.scan(/<h[12][^>]*>\s*([A-Z][a-z]+(?: [A-Z][a-z]+){1,})/).flatten.uniq
  issues << "Title Case: #{title_case.first}" if title_case.any?

  [rel, issues] if issues.any?
end

findings.each { |rel, issues| puts format("  %-52s %s", rel, issues.join("; ")) }
puts
puts "#{files.size} form pages audited, #{findings.size} with findings"
exit(findings.empty? ? 0 : 1)
