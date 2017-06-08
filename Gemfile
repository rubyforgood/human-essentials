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
gem 'jquery-rails', '~> 4.3'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
gem 'yajl-ruby'

# Use Foundation for layout
gem 'foundation-rails', '~> 6.0'
gem 'foundation_rails_helper', '>= 3.0.0.rc2', '< 4.0'
# Simpleform
gem 'simple_form', '~> 3.4'

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# For dashboard charts
gem "chartkick", '~> 2.2'

# For nested resources in forms
gem 'cocoon', '~> 1.2'
gem "groupdate", '~> 3.2'
gem 'jquery-ui-rails', '~> 6.0'
gem 'devise', '= 4.2.1'
gem 'dotenv-rails', '~> 2.2'
gem 'unicorn', '~> 5.3'
# For PDF generation
gem 'prawn-rails', '~> 1.0'
gem 'therubyracer', '~> 0.12',  platforms: :ruby
# Logo attachments
gem 'devise_invitable'
gem 'paperclip', '= 5.1.0'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', '~> 9.0', platform: :mri
  gem 'pry', '~> 0.10'

  # Inherited gems
  gem 'awesome_print', '~> 1.7'
  gem 'guard-rspec', '~> 4.7'
  gem 'rspec-rails', '~> 3.5'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.0.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring', '~> 2.0'
  gem 'spring-watcher-listen', '~> 2.0.0'

  gem 'annotate', '~> 2.6'
  gem 'binding_of_caller', '~> 0.7'
  gem 'better_errors', '~> 2.1'
  gem 'capistrano-rails', '~> 1.2'
  gem 'capistrano-rbenv', '~> 2.1'
  gem 'capistrano-bundler', '~> 1.2'
  gem 'capistrano3-puma', '~> 3.1'
end

group :test do
  gem 'capybara', '~> 2.13'
  gem 'factory_girl_rails', '~> 4.8'
  gem 'database_cleaner', '~> 1.5'
  gem 'rails-controller-testing', '~> 1.0'
  gem 'launchy', '~> 2.4'
  gem 'poltergeist', '~> 1.15'
  gem 'phantomjs', '~> 2.1', require: "phantomjs/poltergeist"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', '~> 1.2', platforms: [:mingw, :mswin, :x64_mingw, :jruby]