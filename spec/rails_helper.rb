# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= "test"
require 'simplecov'
require File.expand_path("../config/environment", __dir__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "spec_helper"
require "rspec/rails"
require "capybara/rails"
require "capybara/rspec"
require "capybara-screenshot/rspec"
require "pry"
require 'sidekiq/testing'
require 'webdrivers'
require 'knapsack_pro'

KnapsackPro::Adapters::RSpecAdapter.bind

Sidekiq::Testing.fake! # fake is the default mode

SimpleCov.start

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
  options = Selenium::WebDriver::Chrome::Options.new(args: args)
  options.add_preference(:download, prompt_for_download: false, default_directory: DownloadHelper::PATH.to_s)
  options.add_preference(:browser, set_download_behavior: { behavior: 'allow' })

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
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

def with_features(**features)
  adapter = Flipper::Adapters::Memory.new
  flipper = Flipper.new(adapter)
  features.each do |feature, enabled|
    if enabled
      flipper.enable(feature)
    else
      flipper.disable(feature)
    end
  end
  stub_const('Flipper', flipper)
  yield
end

def stub_addresses
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
  config.use_transactional_fixtures = false

  # Location for fixtures (logo, etc)
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # Persistence for failures
  config.example_status_persistence_file_path = "spec/example_failures.txt"

  # Make FactoryBot easier.
  config.include FactoryBot::Syntax::Methods

  # Stub out Geocoder or else...
  config.before(:all) do
    stub_addresses
  end

  # set driver for system tests
  config.before(:each, type: :system) do
    clear_downloads
    driven_by :chrome
    Capybara.server = :puma, { Silent: true }
  end

  config.after(:each, type: :system, js: true) do
    clear_downloads
  end

  # Preparatifyication
  config.before(:suite) do
    Rails.logger.info <<~ASCIIART
      -~~==]}>        ######## ###########  ####      ########    ###########
      -~~==]}>      #+#    #+#    #+#     #+# #+#    #+#     #+#     #+#
      -~~==]}>     +#+           +#+    +#+   +#+   +#+      +#+    +#+
      -~~==]}>    +:++#++:++    +:+    +:++#++:++  +:++#++:++      +:+
      -~~==]}>          +:+    +:+    +:+    +:+  +:+     +:+     +:+
      -~~==]}>  :+:    :+:    :+:    :+:    :+:  :+:      :+:    :+:
      -~~==]}>  ::::::::     :::    :::    :::  :::      :::    :::
    ASCIIART

    DatabaseCleaner[:active_record, { model: Partners::Base }]
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean

    DatabaseCleaner[:active_record, { model: ApplicationRecord }]
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean

    raise if Partners::Partner.count > 0
    raise if Organization.count > 0
  end

  config.before(:each) do
    Faker::Config.random = Random.new(42)

    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, type: :system) do
    Faker::Config.random = Random.new(42)

    # Use truncation in the case of doing `browser` tests because it
    # appears that transactions won't work since it really does
    # depend on the database to have records.
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean
  end

  config.before(:each, type: :request) do
    Faker::Config.random = Random.new(42)

    # Use truncation in the case of doing `browser` tests because it
    # appears that transactions won't work since it really does
    # depend on the database to have records.
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean
  end

  config.before(:each) do
    # The database cleaner will now begin at this point
    # up anything after this point when `.clean` is called.
    DatabaseCleaner.start

    # "Dirty" the database by adding the essential records
    # necessary to run tests.
    #
    # If you are using :transaction, it will just rollback any additions
    # when `.clean` is called. Any previous changes will be kept prior to
    # the call `DatabaseCleaner.start`
    #
    # If you are using :truncation, it will erase everything once `.clean`
    # is called.
    seed_base_items_for_tests
    seed_with_default_records
  end

  config.after(:each) do
    # Ensure to clean-up the database by whichever means
    # were specified before the test ran
    DatabaseCleaner.clean

    # Remove any /tmp/storage files that might have been
    # added as a consequence of the test.
    FileUtils.rm_rf(Dir["#{Rails.root}/tmp/storage"])
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

def seed_base_items_for_tests
  Rails.logger.info "-~=> Destroying all Base Items ... "
  BaseItem.delete_all
  base_items = File.read(Rails.root.join("db", "base_items.json"))
  items_by_category = JSON.parse(base_items)
  Rails.logger.info "Creating Base Items: "
  batch_insert = []
  items_by_category.each do |category, entries|
    entries.each do |entry|
      batch_insert << { name: entry["name"], category: category, partner_key: entry["key"] }
    end
  end
  BaseItem.create(batch_insert)
  Rails.logger.info "~-=> Done creating Base Items!"
end

def __start_db_cleaning_with_log
  Rails.logger.info "======> SISYPHUS, PUSH THAT BOULDER BACK UP THE HILL <========"
  Rails.logger.info <<~ASCIIART
        ,-'"""`-.
      ,'         `.
      /        `    \\
    (    /          \)
    |             " |
    (               \)
    `.\\\\          \\ /
      `:.      , \\ ,\\ _
    hh  `:-.___,-`-.{\\\)
          `.         |/ \\
            `.         \\ \\
              `-.      _\\,|
                `.   |,-||
                  `..|| ||
  ASCIIART

  DatabaseCleaner.start
end

def __sweep_up_db_with_log
  DatabaseCleaner.clean
  Rails.logger.info "========= ONE MUST IMAGINE SISYPHUS HAPPY ===================="
  Rails.logger.info <<~ASCIIART
                  /             _
        ,-'"""`-.    /         _ |
      ,'         `.      ;    {\\\)|
    /        `    \\   :. :   /\\ \\
    (    /          | .     _/  \\ \\
    |             " |;  .-``.   _\\,|
    (               |.-`     `-|,-||
    \\\\            /.`         ||.||
      :.     ,   ,`               |.
    amh  :-.___,-``
            .`
          .`
      .-`
  ASCIIART
end

def seed_with_default_records
  Rails.logger.info "\n\n-~=> Creating DEFAULT organization & partner"
  @organization = create(:organization, name: "DEFAULT")
  @partner = create(:partner, organization: @organization)
  Rails.logger.info "\n\n-~=> Creating DEFAULT admins & user"
  @organization_admin = create(:organization_admin, name: "DEFAULT ORG ADMIN", organization: @organization)
  @user = create(:user, organization: @organization, name: "DEFAULT USER")
  @super_admin = create(:super_admin, name: "DEFAULT SUPERADMIN")
  @super_admin_no_org = create(:super_admin_no_org, name: "DEFAULT SUPERADMIN NO ORG")
end
