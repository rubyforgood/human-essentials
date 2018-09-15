require "capybara-screenshot/rspec"

# Screenshots
Capybara.asset_host = "http://localhost:3000"
Capybara::Screenshot.autosave_on_failure = false
Capybara::Screenshot.append_timestamp = true
Capybara::Screenshot::RSpec.add_link_to_screenshot_for_failed_examples = true
Capybara::Screenshot.register_filename_prefix_formatter(:rspec) do |example|
  "screenshot_#{example.description.tr(' ', '-').gsub(%r{^.*\/spec\/}, '')}"
end
Capybara::Screenshot.prune_strategy = :keep_last_run
