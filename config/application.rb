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
    config.load_defaults 5.0
    config.action_dispatch.return_only_media_type_on_content_type = false

    config.active_job.queue_adapter = :sidekiq
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    # the framework and any gems in your application.
  end
end
