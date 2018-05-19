source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'api-auth', '~> 1.5'
gem 'bootstrap-sass'
gem "bugsnag"
gem 'chartkick', '~> 2.2'
gem 'cocoon', '~> 1.2' # For nested resources in forms
gem 'coffee-rails', '~> 4.2'
gem 'devise', '~> 4.4'
gem 'devise_invitable'
gem 'dotenv-rails', '~> 2.2'
gem "font-awesome-rails"
gem "font-ionicons-rails"
gem 'groupdate', '~> 3.2'
gem 'jbuilder', '~> 2.5'
gem 'jquery-rails', '~> 4.3'
gem 'jquery-ui-rails', '~> 6.0'
gem 'newrelic_rpm'
gem 'paperclip', '~> 5.2.1'
gem 'pg', '~> 0.2'
gem 'prawn-rails', '~> 1.0' # For PDF generation
gem 'puma', '~> 3.0'
gem 'rails', '~> 5.1.1'
gem 'react-rails'
gem 'sass-rails', '~> 5.0'
gem 'simple_form', '~> 3.4'
gem 'uglifier', '>= 1.3.0'
gem 'therubyracer', '~> 0.12',  platforms: :ruby
gem 'yajl-ruby'
gem 'toastr-rails'

group :development, :test do
  gem 'awesome_print', '~> 1.7'
  gem 'byebug', '~> 9.0', platform: :mri
  gem 'guard-rspec', '~> 4.7'
  gem 'pry', '~> 0.10'
  gem 'rspec-rails', '~> 3.5'
  gem 'terminal-notifier-guard'
  gem 'terminal-notifier'
end

group :development do
  gem 'annotate', '~> 2.6'
  gem 'binding_of_caller', '~> 0.7'
  gem 'better_errors', '~> 2.1'
  gem 'capistrano-rails', '~> 1.2'
  gem 'capistrano-rbenv', '~> 2.1'
  gem 'capistrano-bundler', '~> 1.2'
  gem 'capistrano3-puma', '~> 3.1'
  gem 'capistrano-rails-console', require: false
  gem 'listen', '~> 3.0.5'
  gem 'spring', '~> 2.0'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'capybara', '~> 2.18'
  gem 'capybara-screenshot'
  gem 'database_cleaner', '~> 1.5'
  gem 'factory_bot_rails', '~> 4.8'
  gem 'launchy', '~> 2.4'
  gem 'phantomjs', '~> 2.1', require: "phantomjs/poltergeist"
  gem 'poltergeist', '~> 1.15'
  gem 'rails-controller-testing', '~> 1.0'
  gem 'webmock', '~> 2.1'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', '~> 1.2', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
