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
require 'webdrivers'
require 'knapsack_pro'

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

# https://docs.travis-ci.com/user/chrome
Capybara.register_driver :chrome do |app|
  args = %w[no-sandbox disable-gpu disable-site-isolation-trials window-size=1680,1050]
  args << "headless" unless ENV["NOT_HEADLESS"] == "true"
  capabilities = Selenium::WebDriver::Chrome::Options.new(args: args)
  capabilities.add_preference(:download, prompt_for_download: false, default_directory: DownloadHelper::PATH.to_s)
  capabilities.add_preference(:browser, set_download_behavior: { behavior: 'allow' })

  Capybara::Selenium::Driver.new(app, browser: :chrome, capabilities: capabilities)
end

# Enable JS for Capybara tests
Capybara.javascript_driver = :chrome

Capybara::Screenshot.autosave_on_failure = true
# The driver name should match the Capybara driver config name.
Capybara::Screenshot.register_driver(:chrome) do |driver, path|
  driver.browser.save_screenshot(path)
end

# Set the asset host so that the screenshots look nice
Capybara.asset_host = "http://localhost:3000"

# Only keep the most recent run
Capybara::Screenshot.prune_strategy = :keep_last_run

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
  DEFAULT_TEST_ORGANIZATION_NAME = "DEFAULT"
  DEFAULT_TEST_USER_NAME = "DEFAULT USER"
  DEFAULT_TEST_ORG_ADMIN_USER_NAME = "DEFAULT ORG ADMIN"
  DEFAULT_TEST_SUPER_ADMIN_USER_NAME = "DEFAULT SUPERADMIN"
  DEFAULT_TEST_SUPER_ADMIN_NO_ORG_USER_NAME = "DEFAULT SUPERADMIN NO ORG"
  DEFAULT_TEST_PARTNER_NAME = "DEFAULT PARTNER"
  DEFAULT_USER_PASSWORD = "password!"
  # rubocop:enable Lint/ConstantDefinitionInBlock

  def define_global_variables
    @organization = Organization.find_by!(name: DEFAULT_TEST_ORGANIZATION_NAME)

    user_names = [
      DEFAULT_TEST_USER_NAME,
      DEFAULT_TEST_ORG_ADMIN_USER_NAME,
      DEFAULT_TEST_SUPER_ADMIN_USER_NAME,
      DEFAULT_TEST_SUPER_ADMIN_NO_ORG_USER_NAME
    ]
    users = User.where(name: user_names)
    @organization_admin = users.find { |u| u.name == DEFAULT_TEST_ORG_ADMIN_USER_NAME }
    @user = users.find { |u| u.name == DEFAULT_TEST_USER_NAME }
    @super_admin = users.find { |u| u.name == DEFAULT_TEST_SUPER_ADMIN_USER_NAME }
    @super_admin_no_org = users.find { |u| u.name == DEFAULT_TEST_SUPER_ADMIN_NO_ORG_USER_NAME }

    @partner = Partner.find_by!(name: DEFAULT_TEST_PARTNER_NAME)
  end

  def seed_base_data_for_tests
    # Create base items that are used to handle seeding Organization with items
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

    # Create default organization
    organization = FactoryBot.create(:organization, name: DEFAULT_TEST_ORGANIZATION_NAME)

    # Create default users
    FactoryBot.create(:organization_admin, organization: organization, name: DEFAULT_TEST_ORG_ADMIN_USER_NAME)
    FactoryBot.create(:user, organization: organization, name: DEFAULT_TEST_USER_NAME)
    FactoryBot.create(:super_admin, name: DEFAULT_TEST_SUPER_ADMIN_USER_NAME)
    FactoryBot.create(:super_admin_no_org, name: DEFAULT_TEST_SUPER_ADMIN_NO_ORG_USER_NAME)

    # Seed with default partner record
    FactoryBot.create(:partner, organization: organization, name: DEFAULT_TEST_PARTNER_NAME)
  end

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
             "address" => "1500 Remount Road, Front Royal, VA",
             "state" => "Virginia",
             "state_code" => "VA",
             "country" => "United States",
             "country_code" => "US"
           }
         ]
       )
     end

    seed_base_data_for_tests
  end

  config.before(:each, type: :system) do
    clear_downloads
    driven_by :chrome
    Capybara.server = :puma, { Silent: true }
  end

  config.before(:each) do
    # Defined shared @ global variables used throughout the test suite.
    define_global_variables
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
