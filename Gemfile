source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.0.2'
# Use postgresql as the database for Active Record
gem 'pg', '~> 0.18'
# Use Puma as the app server
gem 'puma', '~> 3.0'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
gem 'yajl-ruby'

# Use Foundation for layout
gem 'foundation-rails', '~> 6.0'
gem 'foundation_rails_helper', '>= 3.0.0.rc2', '< 4.0'
# Simpleform
gem 'simple_form'

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# These are inherited from original app.
gem "chartkick"
gem 'cocoon'
gem "groupdate"
gem 'jquery-ui-rails'
gem 'cancancan'
gem 'devise', '= 4.2.1'
gem 'dotenv-rails', group: :production
gem 'unicorn', group: :production
gem 'prawn-rails'
gem 'therubyracer',  platforms: :ruby

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
  gem 'pry'

  # Inherited gems
  gem 'awesome_print'
  gem 'guard-rspec'
  gem 'rspec-rails'
end

group :development do
  # Allow SQLite3 for development envs
  gem 'sqlite3'

  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.0.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'

  # Inherited gems
  gem 'annotate'
  gem 'binding_of_caller'
  gem 'better_errors'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'
#  gem 'quiet_assets' # Is this necessary? It's locked to rails 3.1
end

group :test do
  # Inherited Gems
  gem 'capybara'
  gem 'factory_girl_rails'
  gem 'database_cleaner'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
