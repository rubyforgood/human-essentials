require_relative "boot"

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Diaper
  # Bootstraps the application
  class Application < Rails::Application
    config.to_prepare do
      Devise::SessionsController.layout "devise"
      Devise::PasswordsController.layout "devise"
      Devise::RegistrationsController.layout "application"
    end

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0
    config.legacy_connection_handling = false
    config.action_dispatch.return_only_media_type_on_content_type = false
    config.exceptions_app = routes

    config.active_job.queue_adapter = :delayed_job

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    # the framework and any gems in your application.

    # Set the async mailer jobs to go through the default queue
    # that sidekiq comes with. This way `.deliver_later` will
    # generate a job that will be processed by the exisiting
    # sidekiq worker that is only taking work from the `default`
    # queue.
    config.action_mailer.deliver_later_queue_name = 'default'
  end
end
