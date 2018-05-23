# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'spec_helper'
require 'rspec/rails'
require 'capybara/rails'
require 'pry'
require "paperclip/matchers"

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
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }
Dir[Rails.root.join("spec/controllers/shared_examples/*.rb")].each {|f| require f}

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
  config.include Paperclip::Shoulda::Matchers

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
    DatabaseCleaner.clean_with(:truncation, except: %w(ar_internal_metadata))
    DatabaseCleaner.strategy = :transaction
    __start_db_cleaning_with_log
     __lint_with_log
    __sweep_up_db_with_log
  end

  config.before(:each) do
    __start_db_cleaning_with_log

    # prepare a default @organization and @user to always be available for testing
    @organization = create(:organization)
    @organization_admin = create(:organization_admin)
    @user = create(:user)
  end

  config.after(:each) do
    __sweep_up_db_with_log
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

def __start_db_cleaning_with_log
  Rails.logger.info "======> SISYPHUS, PUSH THAT BOULDER BACK UP THE HILL <========"
  DatabaseCleaner.start
end

def __sweep_up_db_with_log
  DatabaseCleaner.clean
  Rails.logger.info "========= ONE MUST IMAGINE SISYPHUS HAPPY ===================="
end

def __lint_with_log
  Rails.logger.info "////////////////// LINTING ////////////////////"
  FactoryBot.lint
  Rails.logger.info "////////////////// END LINT ///////////////////"
end
