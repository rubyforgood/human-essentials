source "https://rubygems.org"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

ruby "2.6.4"

gem "api-auth", "~> 2.3"
gem "bootstrap-sass"
gem "bugsnag"
gem "chartkick"
gem "cocoon"
gem "devise", '>= 4.7.1'
gem "devise_invitable"
gem "dotenv-rails"
gem "flipper"
gem "flipper-active_record"
gem "flipper-ui"
gem "font-awesome-rails"
gem "font-ionicons-rails"
gem "fullcalendar-rails"
gem "geocoder"
gem "groupdate", "~> 4.1"
gem "image_processing"
gem "jbuilder"
gem "jquery-rails"
gem "jquery-ui-rails"
gem "kaminari"
gem "momentjs-rails"
gem "newrelic_rpm"
gem "nokogiri", ">= 1.10.4"
gem "paperclip"
gem "pg", "~> 1.1.3"
gem "prawn-rails"
gem "puma"
gem "rails", "~> 6.0.0"
gem "sass-rails"
gem "sidekiq"
gem "simple_form"
gem "skylight"
gem "sprockets", "~> 3.7.2"
gem "uglifier", ">= 1.3.0"
gem "therubyracer", "~> 0.12", platforms: :ruby
gem "yajl-ruby"
gem "toastr-rails"
gem "webpacker", "> 4.0"
gem 'sidekiq-scheduler'
gem 'bootstrap-datepicker-rails'

group :development, :test do
  gem "awesome_print"
  gem "fakeredis", require: "fakeredis/rspec"
  gem "guard-rspec"
  gem "pry-rails"
  gem "pry-remote"
  gem "pry-nav"
  gem 'rb-readline', '~> 0.5.3'
  gem "rspec-rails", "~> 4.0.0.beta3"
  gem "rubocop"
  gem "terminal-notifier-guard"
  gem "terminal-notifier"
  gem "timecop"
  gem "faker"
end

group :development do
  gem "annotate"
  gem "binding_of_caller"
  gem "better_errors"
  gem "capistrano-rails"
  gem "capistrano-rvm"
  gem "capistrano-bundler"
  gem "capistrano3-puma"
  gem "capistrano-rails-console", require: false
  gem 'capistrano-sidekiq'
  gem "listen", "~> 3.1.5"
  gem "rails-erd"
  gem "spring"
  gem "spring-watcher-listen"
  gem "web-console"
end

group :test do
  gem "capybara", "~> 3.12"
  gem "capybara-screenshot"
  gem "database_cleaner"
  gem "factory_bot_rails"
  gem "launchy"
  gem 'webdrivers', '~> 3.0'
  gem "rails-controller-testing"
  gem 'simplecov'
  gem "webmock", "~> 3.5"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem

# This 'if' may seem redundant but for some reason it is necessary to suppress
# a warning on non (Windows or JRuby) platforms.
if %w(mingw mswin x64_mingw jruby).include?(RUBY_PLATFORM)
  gem "tzinfo-data", "~> 1.2", platforms: %i(mingw mswin x64_mingw jruby)
end
