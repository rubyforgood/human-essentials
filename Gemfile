source "https://rubygems.org"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

ruby "3.0.2"

gem 'azure-storage', '~> 0.15.0.preview', require: false
gem 'azure-storage-blob'
gem 'bootstrap', '~> 4.6.1'
gem 'bootstrap-daterangepicker-rails'
gem 'bootstrap-select-rails'
gem "bugsnag"
gem "chartkick"
gem "cocoon"
gem 'delayed_job_active_record'
gem 'delayed_job_web'
gem "devise", '>= 4.7.1'
gem 'devise-secure_password', '~> 2.0'
gem 'discard', '~> 1.0'
gem "devise_invitable"
gem "dotenv-rails"
gem "filterrific"
gem "flipper"
gem "flipper-active_record"
gem "flipper-ui"
gem "font-awesome-rails"
gem "font-ionicons-rails"
gem "fullcalendar-rails"
gem "geocoder"
gem "groupdate", "~> 6.0"
gem "image_processing"
gem "jbuilder"
gem "jquery-rails"
gem "jquery-ui-rails"
gem "jwt"
gem "kaminari"
gem "mini_racer", "~> 0.6.0"
gem "momentjs-rails"
gem "money-rails"
gem "nokogiri", ">= 1.10.4"
gem "pg", "~> 1.3.0"
gem "simple_form"
gem "prawn-rails"
gem "puma"
gem "rails", "~> 6.1.0"
gem "sass-rails"
gem "strong_migrations", "~> 0.7.0"
gem "sprockets", "~> 4.0.0"
gem "toastr-rails"
gem "uglifier", ">= 1.3.0"
gem 'webpacker', '~> 5.0'
gem "recaptcha"
gem "paper_trail" # for tracking history of InventoryItem

group :production do
  gem 'lograge' # Reduce the noise of logs and include custom fields to it for easier access
  gem "skylight"
end

group :development, :test, :staging do
  gem 'factory_bot_rails'
  gem "database_cleaner", '1.8.5'
  gem 'faker'
end

group :development, :test do
  gem "awesome_print"
  gem "brakeman"
  gem "fakeredis", require: "fakeredis/rspec"
  gem "guard-rspec"
  gem "knapsack_pro"
  gem "pry-doc"
  gem "pry-rails"
  gem "pry-remote"
  gem "pry-nav"
  gem "rb-readline", "~> 0.5.0"
  gem "rspec-rails", "~> 5.0.0"
  gem "rubocop"
  gem "rubocop-rails", "~> 2.9.0"
  gem "standard", "~> 1.0"
  gem "terminal-notifier-guard"
  gem "terminal-notifier"
end

group :development do
  gem "annotate"
  gem "binding_of_caller"
  gem "better_errors"
  gem "bullet"
  gem 'foreman'
  gem "letter_opener"
  gem "listen", "~> 3.7.0"
  gem "rails-erd"
  gem "web-console"
end

group :test do
  gem "capybara", "~> 3.0"
  gem "capybara-screenshot"
  gem "launchy"
  gem 'magic_test'
  gem "orderly", "~> 0.1" # used for feature testing where this appears before that
  gem "rails-controller-testing"
  gem "rspec-retry"
  gem 'simplecov'
  gem 'shoulda-matchers', '~> 5.0'
  gem 'webdrivers', '~> 5.0'
  gem "webmock", "~> 3.0"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem

# This 'if' may seem redundant but for some reason it is necessary to suppress
# a warning on non (Windows or JRuby) platforms.
if %w(mingw mswin x64_mingw jruby).include?(RUBY_PLATFORM)
  gem "tzinfo-data", "~> 1.0", platforms: %i(mingw mswin x64_mingw jruby)
end
