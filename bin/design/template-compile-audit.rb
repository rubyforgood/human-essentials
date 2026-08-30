# Does every view template actually compile?
#
# Run: bin/rails runner bin/design/template-compile-audit.rb
#
# Written after a real defect that everything else missed. A sweep that rewrote 55 row actions
# interpolated Python's `None` into one of them, leaving
#
#     essentials_row_icon_action "Distribution complete", ..., icon: "bi-check-circle"None
#
# in `distributions/_pickup_day_row`. `erb_lint` passed -- the ERB *tags* are well formed, and it
# does not compile the Ruby inside them. `rubocop` passed -- it does not read templates. All 3,159
# specs passed, and `/distributions/pickup_day` returned **200**, because Rails skips a partial
# rendered through `collection:` when the collection is empty and never compiles it. The page 500s
# the moment a pick-up exists for the day being looked at. Brakeman found it, as a parse error
# buried under a heading nobody reads.
#
# So: compile every template, once, and say which ones do not. It costs about a second and it
# closes a gap that four other checks left open.
#
# A compiled template is a *method body*, so the source is wrapped before compiling -- `<%= yield %>`
# is legal there and "Invalid yield" at the top level is the checker being wrong, not the view.
# Getting that backwards reported four healthy partials on the first run.

paths = Rails.root.glob("app/views/**/*.erb").sort
failures = []

paths.each do |path|
  source = File.read(path)
  compiled =
    begin
      ActionView::Template::Handlers::ERB::Erubi.new(source).src
    rescue => e
      failures << [path, "ERB would not parse: #{e.message.lines.first.to_s.strip}"]
      next
    end

  begin
    RubyVM::InstructionSequence.compile("def __template_check__(*)\n#{compiled}\nend")
  rescue SyntaxError => e
    detail = e.message.lines.reject { |l| l.strip.empty? }.first(2).map(&:strip).join(" ")
    failures << [path, detail]
  end
end

puts "#{paths.size} templates compiled"

if failures.empty?
  puts "\nevery template compiles"
  exit 0
end

puts
failures.each do |path, message|
  puts "  FAIL #{path.to_s.sub("#{Rails.root}/", "")}"
  puts "       #{message}"
end
puts "\n#{failures.size} template(s) will raise when rendered"
exit 1
