# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] = "test"

require File.expand_path("../config/environment", __dir__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "spec_helper"
require "rspec/rails"
require "capybara/rails"
require "capybara/rspec"
require "capybara-screenshot/rspec"
require "pry"
require 'knapsack_pro'
require 'paper_trail/frameworks/rspec'
require_relative 'inventory'

KnapsackPro::Adapters::RSpecAdapter.bind

# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Rails.root.glob("spec/support/**/*.rb").sort.each { |f| require f }
Rails.root.glob("spec/controllers/shared_examples/*.rb").sort.each { |f| require f }

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.

# As of Raild 6 upgrade, this causes an error:
# PG::ConnectionBad:
#  connection is closed
# Likely due to some changed order of operations
# ActiveRecord::Migration.maintain_test_schema!

# If an element is hidden, Capybara should ignore it
Capybara.ignore_hidden_elements = true

# Match a control by its **accessible name**, not only by visible text.
#
# Every visible action in a table row is a 28px icon now, named by `aria-label` and `data-tooltip`
# rather than by a text node -- design.md, Row actions. Without this, `click_on "Delete"` stops
# matching the Delete button, and seventeen specs did. They are not wrong: "Delete" *is* what that
# control is called, and it is what a screen reader announces. This makes Capybara agree.
#
# Three specs previously worked around the setting being off. Their comments are left in place and
# corrected rather than deleted, so the reason they were written that way survives.
Capybara.enable_aria_label = true

require "capybara/cuprite"
Capybara.register_driver(:local_cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [1200, 800],
    js_errors: true,
    headless: ENV["NOT_HEADLESS"] != "true",
    slowmo: ENV["SLOWMO"]&.to_f,
    process_timeout: 60,
    timeout: 20,
    browser_options: ENV["DOCKER"] ? { "no-sandbox" => nil } : {}
  )
end

# Enable JS for Capybara tests
Capybara.javascript_driver = :local_cuprite

# disable CSS transitions and js animations
Capybara.disable_animation = true

# Filtering is asynchronous now: a filter bar submits into a Turbo Frame and the results are
# swapped in place. Capybara's 2s default is thin for a request-and-render under a full suite, and
# the failures it produces read as wrong counts rather than as timeouts. This only lengthens the
# path to a genuine failure; a passing assertion still returns as soon as it is true.
Capybara.default_max_wait_time = 5

Capybara::Screenshot.autosave_on_failure = true
# The driver name should match the Capybara driver config name.
Capybara::Screenshot.register_driver(:local_cuprite) do |driver, path|
  driver.save_screenshot(path)
end

# Set the asset host so that the screenshots look nice
Capybara.asset_host = "http://localhost:3000"

# Only keep the most recent run
Capybara::Screenshot.prune_strategy = :keep_last_run

# Set the directory Capybara should save screenshots to
# This monkeypatch is needed to separate screenshots from downloads
module Capybara
  module Screenshot
    def self.capybara_tmp_path
      Rails.root.join("tmp", "screenshots")
    end
  end
end

RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :view
  config.include Devise::Test::ControllerHelpers, type: :helper
  config.include Devise::Test::IntegrationHelpers, type: :feature
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include Devise::Test::IntegrationHelpers, type: :request

  config.include ActiveSupport::Testing::TimeHelpers, type: :system
  config.include ActiveSupport::Testing::TimeHelpers, type: :feature

  config.include DownloadHelper, type: :system

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # Location for fixtures (logo, etc)
  config.fixture_paths = ["#{::Rails.root}/spec/fixtures"]

  # Persistence for failures
  config.example_status_persistence_file_path = "spec/example_failures.txt"

  # Make FactoryBot easier.
  config.include FactoryBot::Syntax::Methods

  #
  # --------------------
  # START - Seeding helpers for tests setup
  # --------------------
  #

  #
  # Disable this rubocop rule here so we are permitted to set constants within
  # the RSpec.configure block.
  # rubocop:disable Lint/ConstantDefinitionInBlock
  DEFAULT_TEST_ORGANIZATION_NAME = "STARTER"
  DEFAULT_TEST_USER_NAME = "DEFAULT USER"
  DEFAULT_TEST_ORG_ADMIN_USER_NAME = "DEFAULT ORG ADMIN"
  DEFAULT_TEST_SUPER_ADMIN_USER_NAME = "DEFAULT SUPERADMIN"
  DEFAULT_TEST_SUPER_ADMIN_NO_ORG_USER_NAME = "DEFAULT SUPERADMIN NO ORG"
  DEFAULT_TEST_PARTNER_NAME = "DEFAULT PARTNER"
  DEFAULT_USER_PASSWORD = "password!"
  # rubocop:enable Lint/ConstantDefinitionInBlock

  # --------------------
  # END - Seeding helpers for tests setup
  # --------------------

  # Preparatifyication
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation, except: %w[ar_internal_metadata])

    # Stub out the Geocoder since we don't want to hit the API
    Geocoder.configure(lookup: :test)

    Geocoder::Lookup::Test.set_default_stub(
      [
        {
          "latitude" => 40.7143528,
          "longitude" => -74.0059731,
          "address" => "1500 Remount Road, Front Royal, VA 22630",
          "state" => "Virginia",
          "state_code" => "VA",
          "country" => "United States",
          "country_code" => "US"
        }
      ]
    )
  end

  config.before(:each, type: :system) do
    clear_downloads
    driven_by :local_cuprite
    Capybara.server = :puma, { Silent: true }
  end

  config.before do
    Faker::UniqueGenerator.clear # Clears used values to avoid retry limit exceeded error
  end

  # rubocop:disable Rails/RedundantTravelBack
  config.after(:each) do
    travel_back
  end
  # rubocop:enable Rails/RedundantTravelBack

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

def current_role
  current_user.roles.first
end

def html_body(mail)
  mail.body.parts.find { |p| p.content_type =~ /html/ }.body.encoded
end

def text_body(mail)
  mail.body.parts.find { |p| p.content_type =~ /text/ }.body.encoded
end

def select2(node, select_name, value, position: nil)
  position_str = position ? "[#{position}]" : ""
  xpath = %((//div[contains(@class, "#{select_name}")]//span[contains(@class, "select2-container")])#{position_str})
  container = node.find(:xpath, xpath)
  container.click
  container.find(:xpath, '//li[contains(@class, "select2-results__option")][@role="option"]', text: value).click
end

# Runs the provided block of code that will change select2 dropdown. Waits until
# select2 javascript has finished running to return
#
# @param select2 [String] The CSS selector for the Select2 dropdown element.
# @param container [String, nil] The CSS selector for the container element
# @yield Block to execute that will trigger Select2 change
#
# @example Usage
#   # Wait for Select2 dropdown with CSS selector '.select2' inside container '.container'
#   await_select2('.select2', '.container') do
#     # Perform actions that trigger a change in the Select2 dropdown
#   end
def await_select2(select2, container = nil, &block)
  #
  # **The starting id is read with a retrying finder, not a Nokogiri snapshot.** This used to do
  # `Nokogiri::HTML.parse(page.body)` and take `children.first["data-select2-id"]`. That is a
  # single non-retrying read of whatever the DOM happened to be: select2 stamps the attribute when
  # it initialises, so if the snapshot was taken first the attribute was absent, `nil.to_i` gave
  # **0**, and the wait below looked for id "1" — which never arrives — until it timed out ten
  # seconds later. It surfaced once in fifteen full-suite runs and passed every time the file was
  # run on its own.
  #
  # **The wait is anchored to the element it was given.** The old selector was
  # `"#{container} select option[...]"`, which dropped `select2` and matched *any* `select` on the
  # page; with `container` nil — which is how all eight call sites use it — it rendered as
  # `" select option[...]"`, leading space and all.
  #
  scope = container ? "#{container} " : ""
  first_option = find("#{scope}#{select2} option[data-select2-id]",
    match: :first, visible: :all, wait: 10)
  current_id = first_option["data-select2-id"].to_i

  yield

  # select2 re-stamps the options when it rebuilds them, so the next id appearing means the
  # rebuild has happened.
  find("#{scope}#{select2} option[data-select2-id=\"#{current_id + 1}\"]",
    visible: :all, wait: 10)
end

# TODO: Remove the following workaround once the following commit is in
# in a new release of Devise:
# https://github.com/heartcombo/devise/commit/591b03a6c010f47976f7033370a8165c5324a82c
ActiveSupport.on_load(:action_mailer) do
  Rails.application.reload_routes_unless_loaded
end
