# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "spec_helper"
require "rspec/rails"
require "capybara/rails"
require "capybara/rspec"
require "pry"

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
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/controllers/shared_examples/*.rb")].each { |f| require f }

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

# If an element is hidden, Capybara should ignore it
Capybara.ignore_hidden_elements = true

# https://docs.travis-ci.com/user/chrome
Capybara.register_driver :chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new(args: %w[no-sandbox headless disable-gpu])

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

# Enable JS for Capybara tests
Capybara.javascript_driver = :chrome

RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :view
  config.include Devise::Test::IntegrationHelpers, type: :feature

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # Location for fixtures (logo, etc)
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # Make FactoryBot easier.
  config.include FactoryBot::Syntax::Methods

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

    Rails.logger.info "-~=> Destroying all Canonical Items ... "
    CanonicalItem.delete_all
    # Canonical Items are independent of all other data, though other models depend on
    # their existence, so we'll persist them
    DatabaseCleaner.clean_with(:truncation, except: %w(ar_internal_metadata canonical_items))
    DatabaseCleaner.strategy = :transaction
    __start_db_cleaning_with_log
    __sweep_up_db_with_log
    seed_canonical_items_for_tests
  end

  config.before(:each) do
    __start_db_cleaning_with_log

    # prepare a default @organization and @user to always be available for testing
    Rails.logger.info "\n\n-~=> Creating DEFAULT organization"
    @organization = create(:organization, name: "DEFAULT")
    Rails.logger.info "\n\n-~=> Creating DEFAULT admin & user"
    @organization_admin = create(:organization_admin, name: "DEFAULT ADMIN")
    @user = create(:user, organization: @organization, name: "DEFAULT USER")

    Rails.logger.info "\n\n-~=> #{self.class.description} ::::::::::::::::::::::"
  end

  config.after(:each) do
    __sweep_up_db_with_log
    FileUtils.rm_rf(Dir["#{Rails.root}/tmp/storage"])
  end

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end

def seed_canonical_items_for_tests
  Rails.logger.info "-~=> Destroying all Canonical Items ... "
  CanonicalItem.delete_all
  canonical_items = File.read(Rails.root.join("db", "canonical_items.json"))
  items_by_category = JSON.parse(canonical_items)
  Rails.logger.info "Creating Canonical Items: "
  batch_insert = []
  items_by_category.each do |category, entries|
    entries.each do |entry|
      batch_insert << { name: entry["name"], category: category }
    end
  end
  CanonicalItem.create(batch_insert)
  Rails.logger.info "~-=> Done creating Canonical Items!"
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
