# Every view template compiles.
#
# This exists because a defect got past everything else. A sweep that rewrote 55 row actions
# interpolated Python's `None` into one of them, leaving `icon: "bi-check-circle"None` in
# `distributions/_pickup_day_row`.
#
#   - `erb_lint` passed: the ERB *tags* are well formed, and it does not compile the Ruby in them.
#   - `rubocop` passed: it does not read templates.
#   - All 3,159 specs passed.
#   - `/distributions/pickup_day` returned 200, because Rails skips a partial rendered through
#     `collection:` when the collection is empty and never compiles it. The page 500s the moment a
#     pick-up exists for the day being looked at, which no spec sets up.
#
# Brakeman found it, as a parse error under a heading nobody reads. This turns that into a failure.
#
# A compiled template is a method body, so the source is wrapped before compiling -- `<%= yield %>`
# is legal there, and treating "Invalid yield" at the top level as a defect reported four healthy
# partials the first time.
RSpec.describe "Every view template" do
  it "compiles" do
    failures = Rails.root.glob("app/views/**/*.erb").sort.filter_map do |path|
      source = File.read(path)
      begin
        compiled = ActionView::Template::Handlers::ERB::Erubi.new(source).src
        RubyVM::InstructionSequence.compile("def __template_check__(*)\n#{compiled}\nend")
        nil
      rescue SyntaxError, StandardError => e
        "#{path.to_s.sub("#{Rails.root}/", "")}: #{e.message.lines.first.to_s.strip}"
      end
    end

    expect(failures).to be_empty, -> { "These templates raise when rendered:\n  #{failures.join("\n  ")}" }
  end
end
