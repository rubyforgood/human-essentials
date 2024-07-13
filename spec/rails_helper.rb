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
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }
Dir[Rails.root.join("spec/controllers/shared_examples/*.rb")].sort.each { |f| require f }

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.

# As of Raild 6 upgrade, this causes an error:
# PG::ConnectionBad:
#  connection is closed
# Likely due to some changed order of operations
# ActiveRecord::Migration.maintain_test_schema!

# If an element is hidden, Capybara should ignore it
Capybara.ignore_hidden_elements = true

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
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

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

    ["1500 Remount Road, Front Royal, VA 22630",
      "123 Donation Site Way",
      "Smithsonian Conservation Center new"].each do |address|
      Geocoder::Lookup::Test.add_stub(
        address, [
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
  end

  config.before(:each, type: :system) do
    clear_downloads
    driven_by :local_cuprite
    Capybara.server = :puma, { Silent: true }
  end

  config.before(:each) do
    if ENV['EVENTS_READ'] == 'true'
      allow(Event).to receive(:read_events?).and_return(true)
    end
  end

  config.before do
    Faker::UniqueGenerator.clear # Clears used values to avoid retry limit exceeded error
  end

  config.after(:each) do
    travel_back
  end

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
  page_html = Nokogiri::HTML.parse(page.body)
  page_html = page_html.css(container).first unless container.nil?
  select2_element = page_html.css(select2).first
  current_id = select2_element.children.first["data-select2-id"]

  yield

  find("#{container} select option[data-select2-id=\"#{current_id.to_i + 1}\"]", wait: 10)
end

def seed_base_items
  base_items = File.read(Rails.root.join("db", "base_items.json"))
  items_by_category = JSON.parse(base_items)
  base_items_data = items_by_category.map do |category, entries|
    entries.map do |entry|
      {
        name: entry["name"],
        category: category,
        partner_key: entry["key"],
        updated_at: Time.zone.now,
        created_at: Time.zone.now
      }
    end
  end.flatten

  BaseItem.create!(base_items_data)
end
