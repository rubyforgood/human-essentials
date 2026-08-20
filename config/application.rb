require_relative "boot"

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Diaper
  # Bootstraps the application
  class Application < Rails::Application
    config.to_prepare do
      # Auth screens are migrated to the Ruby for Good design system (ADR 0011).
      Devise::SessionsController.layout "essentials_auth"
      Devise::PasswordsController.layout "essentials_auth"
      Devise::ConfirmationsController.layout "essentials_auth"
      Devise::UnlocksController.layout "essentials_auth"
      Devise::RegistrationsController.layout "essentials_app"
    end

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0
    config.legacy_connection_handling = false
    config.action_dispatch.return_only_media_type_on_content_type = false

    config.active_job.queue_adapter = :delayed_job

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    # the framework and any gems in your application.

    # Set the async mailer jobs to go through the default queue
    # that sidekiq comes with. This way `.deliver_later` will
    # generate a job that will be processed by the existing
    # sidekiq worker that is only taking work from the `default`
    # queue.
    config.action_mailer.deliver_later_queue_name = 'default'

    config.active_support.to_time_preserves_timezone = :zone # New default starting in Rails 8.1

    # Keep the pipeline away from the Tailwind SOURCE. tailwindcss-rails hardcodes its input to
    # app/assets/tailwind/application.css, and the pipeline picks up every app/assets/*
    # directory -- so "application.css" would resolve to a file whose first line is
    # `@import "tailwindcss"`, which is not a stylesheet a browser can use. Only the compiled
    # app/assets/builds/tailwind.css is ever served. Pinned by
    # spec/assets/asset_resolution_spec.rb.
    #
    # Propshaft applies this in its own append_assets_path initializer, so it is set as config
    # rather than by rejecting from the path list afterwards.
    config.assets.excluded_paths = [Rails.root.join("app/assets/tailwind")]
  end
end
