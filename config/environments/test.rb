# 1 Apr 2020 [AMH] : Deprecation warnings have been VERY verbose lately. This hides them.
Warning[:deprecated] = false

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Eager load code on boot in CI. This produces slightly more consistent behavior from
  # various system specs, may improve the accuracy of the simplecov coverage metrics when
  # running with spring, and can improve the runtime of the full test suite in some cases.
  # Disable eager load in local development because the average the additional load time when
  # running a single test file at the time of this comment was around 2-3 seconds slower with
  # eager loading enabled. For a single test within a file it lost even more time.
  config.eager_load = ENV["CI"] == "true"

  config.action_mailer.default_url_options = { host: "localhost" }

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false
  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test
  config.active_job.queue_adapter = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Store files locally.
  config.active_storage.service = :test

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Tell Rails to use the system default timezone. This avoids issues where Timecop
  # freezes to UTC and the fake browser is running under a local timezone
  config.time_zone = 'America/Los_Angeles'
  ENV['TZ'] = 'America/Los_Angeles' # Make Capybara aware of the current time zone
end
