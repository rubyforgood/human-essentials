source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'api-auth', '~> 1.5'
gem 'bootstrap-sass'
gem 'bugsnag'
gem 'chartkick'
gem 'cocoon'
gem 'coffee-rails'
gem 'devise'
gem 'devise_invitable'
gem 'dotenv-rails'
gem 'font-awesome-rails'
gem 'font-ionicons-rails'
gem 'groupdate', '~> 3.2'
gem 'jbuilder'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'newrelic_rpm'
gem 'paperclip'
gem 'pg', '~> 0.2'
gem 'prawn-rails'
gem 'puma'
gem 'rails', '~> 5.2.0'
gem 'react-rails', '~> 2.3.0'
gem 'sass-rails'
gem 'simple_form'
gem 'skylight'
gem 'uglifier', '>= 1.3.0'
gem 'therubyracer', '~> 0.12',  platforms: :ruby
gem 'yajl-ruby'
gem 'toastr-rails'

group :development, :test do
  gem 'awesome_print'
  gem 'byebug', '~> 9.0', platform: :mri
  gem 'guard-rspec'
  gem 'pry'
  gem 'rspec-rails', '~> 3.5'
  gem 'terminal-notifier-guard'
  gem 'terminal-notifier'
  gem 'rubocop'
end

group :development do
  gem 'annotate'
  gem 'binding_of_caller'
  gem 'better_errors'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'
  gem 'capistrano-bundler'
  gem 'capistrano3-puma'
  gem 'capistrano-rails-console', require: false
  gem 'listen', '~> 3.0.5'
  gem 'spring'
  gem 'spring-watcher-listen'
  gem 'web-console'
end

group :test do
  gem 'capybara', '~> 2.18'
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'launchy'
  gem 'chromedriver-helper'
  gem 'selenium-webdriver'
  gem 'rails-controller-testing'
  gem 'webmock', '~> 2.1'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', '~> 1.2', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
