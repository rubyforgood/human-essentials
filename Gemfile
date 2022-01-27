source "https://rubygems.org"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

ruby "3.0.2"

###### BASIC FRAMEWORKS ######

# User management and login workflow.
gem "devise", '>= 4.7.1'
# Postgres database adapter.
gem "pg", "~> 1.3.0"
# Web server.
gem "puma"
# Rails web framework.
gem "rails", "~> 6.1.0"

###### MODELS / DATABASE #######

# These two gems are used to hook into ActiveStorage to store blobs in Azure Storage Service.
gem 'azure-storage', '~> 0.15.0.preview', require: false
gem 'azure-storage-blob'
# Adds soft delete functionality for models.
gem 'discard', '~> 1.0'
# Adds grouping by date/month/etc to queries.
gem "groupdate", "~> 6.0"
# Treats attributes like money, which knows about dollars and cents.
gem "money-rails"
# Tracks history / audits models.
gem "paper_trail"
# Enforces "safe" migrations.
gem "strong_migrations", "~> 0.7.0"

##### JAVSCRIPT/CSS/ASSETS #######

# Bootstrap is a library for HTML, CSS and JS.
gem 'bootstrap', '~> 4.6.0'
# Displays a date range picker, i.e. a way for a user to select a start and end date in
# a single widget.
gem 'bootstrap-daterangepicker-rails'
# Delivers assets for a superpowered dropdown using Bootstrap.
gem 'bootstrap-select-rails'
# Creates JavaScript graphs.
gem "chartkick"
# Installs fonts for Rails frontend.
gem "font-awesome-rails"
gem "font-ionicons-rails"
# A jQuery calendar widget.
gem "fullcalendar-rails"
# jQuery framework (DOM methods, Ajax, chaining, etc.)
gem "jquery-rails"
gem "jquery-ui-rails"
# JavaScript date handling functions
gem "momentjs-rails"
# SASS CSS framework (nested selectors, variables, etc.)
gem "sass-rails"
# Toast (non-blocking notification) library.
gem "toastr-rails"
# JavaScript minified, used in asset compilation.
gem "uglifier", ">= 1.3.0"
# JavaScript bundler.
gem 'webpacker', '~> 5.0'
# Used to verify that the user is a human.
gem "recaptcha"

##### VIEWS/CONTROLLERS #####

# Adds easy links to add or remove associations in a form (e.g. line items)
gem "cocoon"
# Adds filter support to models and views.
gem "filterrific"
# Generates JSON structures via a builder interface.
gem "jbuilder"
# Pagination of models for use in views.
gem "kaminari"
# Reduces boilerplate HTML code when writing forms.
gem "simple_form"
# Generate PDFs as views.
gem "prawn-rails"

##### ADDITIONAL FUNCTIONS #####

# External service that monitors exceptions and reports them to Slack or e-mail.
gem "bugsnag"
# Runs jobs asynchronously using the database as a queue.
gem 'delayed_job_active_record'
# UI for showing job status.
gem 'delayed_job_web'
# Enforces secure passwords for users via policies.
gem 'devise-secure_password', '~> 2.0'
# Sends invitations via e-mail for new users.
gem "devise_invitable"
# Environment variable and configuration management.
gem "dotenv-rails"
# Feature flagging and management.
gem "flipper"
gem "flipper-active_record"
gem "flipper-ui"
# Calculates latitude and longitude from an address.
gem "geocoder"
# JSON Web Token encoding / decoding (e.g. for links in e-mails)
gem "jwt"

##### DEPENDENCY PINS ######
# These are gems that aren't used directly, only as dependencies for other gems.
# Technically they don't need to be in this Gemfile at all, but we are pinning them to
# specific versions for compatibility reasons.
gem "mini_racer", "~> 0.6.0"
gem "nokogiri", ">= 1.10.4"
gem "image_processing"
gem "sprockets", "~> 4.0.0"

group :production do
  # Reduce the noise of logs and include custom fields to it for easier access
  gem 'lograge'
  # Profiler (third party app) showing performance and metrics.
  gem "skylight"
end

group :development, :test, :staging do
  # Generate models based on factory definitions.
  gem 'factory_bot_rails'
  # Ensure the database is in a clean state on every test.
  gem "database_cleaner", '1.8.5'
  # Generate fake data for use in tests.
  gem 'faker'
end

group :development, :test do
  # Command line tool for better object printing.
  gem "awesome_print"
  # Scan for vulnerabilities and other static analysis.
  gem "brakeman"
  # Re-run specs when files change.
  gem "guard-rspec"
  # Split tests in a suite across multiple runners.
  gem "knapsack_pro"
  # Show core documentation in command line.
  gem "pry-doc"
  # Rails plugin for command line.
  gem "pry-rails"
  # Connect to a remotely running command line instance.
  gem "pry-remote"
  # Add-on for command line to create a simple debugger.
  gem "pry-nav"
  # RSpec behavioral testing framework for Rails.
  gem "rspec-rails", "~> 5.0.0"
  # Allow retrying flaky RSpec tests.
  gem "rspec-retry"
  # Static analysis / linter.
  gem "rubocop"
  # Rails add-on for static analysis.
  gem "rubocop-rails", "~> 2.9.0"
  # Default rules for Rubocop.
  gem "standard", "~> 1.0"
end

group :development do
  # Show database columns and indexes inside files.
  gem "annotate"
  # Used as a dependency for better_errors.
  gem "binding_of_caller"
  # Show a better error page on development, including a REPL.
  gem "better_errors"
  # Detect N+1 and other slow queries.
  gem "bullet"
  # Run multiple processes from a Procfile (web, jobs, etc.)
  gem 'foreman'
  # Open sent e-mails in the browser instead of trying to send to a real mail server.
  gem "letter_opener"
  # Used as a dependency for Guard.
  gem "listen", "~> 3.7.0"
  # Generate a diagram based on Rails models.
  gem "rails-erd"
  # Allows to create a console in the browser.
  gem "web-console"
end

group :test do
  # Test using browsers.
  gem "capybara", "~> 3.0"
  # Create screenshots when doing browser tests.
  gem "capybara-screenshot"
  # Generate Capybara tests in the browser and debug them.
  gem 'magic_test'
  # Can ensure that text appears before other text.
  gem "orderly", "~> 0.1"
  # Bring back deprecated controller tests.
  gem "rails-controller-testing"
  # Show code coverage.
  gem 'simplecov'
  # More concise test ("should") matchers
  gem 'shoulda-matchers', '~> 5.0'
  # Selenium webdriver automatic installation and update.
  gem 'webdrivers', '~> 5.0'
  # Mock HTTP requests and ensure they are not called during tests.
  gem "webmock", "~> 3.0"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem

# This 'if' may seem redundant but for some reason it is necessary to suppress
# a warning on non (Windows or JRuby) platforms.
if %w(mingw mswin x64_mingw jruby).include?(RUBY_PLATFORM)
  gem "tzinfo-data", "~> 1.2", platforms: %i(mingw mswin x64_mingw jruby)
end
