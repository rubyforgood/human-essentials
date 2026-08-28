Rails.application.configure do
  config.after_initialize do
    Bullet.enable        = true
    Bullet.alert         = false
    Bullet.bullet_logger = true
    Bullet.console       = true
    Bullet.rails_logger  = true
    Bullet.add_footer    = true
  end

  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false
  config.hosts << "diaper.test"
  config.hosts << ".app.github.dev"

  # Reaching the dev server through a proxy -- a TLS-terminating tunnel like localhost.run,
  # GitHub Codespaces port forwarding, or a port forward that changes the port -- means Rails
  # cannot always work out the scheme the browser actually used. It then computes a base_url
  # that disagrees with the Origin header and CSRF rejects every form, which surfaces as
  # "Your session expired".
  #
  # Relaxing the ORIGIN check (not the token) is the right lever: the token is the actual
  # defence, and the origin comparison is the part the proxy breaks. Forcing assume_ssl was
  # wrong -- it fixes an https tunnel and breaks a plain http forward, which is worse,
  # because the forward is the common case.
  config.action_controller.forgery_protection_origin_check = false if ENV["TUNNEL"].present?

  # Show full error reports.
  config.consider_all_requests_local = true
  config.action_mailer.default_url_options = { host: "localhost:3000" }

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Use letter_opener for testing emails
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.perform_deliveries = true

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  config.action_mailer.preview_paths << "#{Rails.root}/lib/previews"

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Store files locally.
  config.active_storage.service = :local

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Adds comments to rendered views so you know which partials are being rendered
  # more easily.
  config.action_view.annotate_rendered_view_with_filenames = true

  require "socket"
  require "ipaddr"
  config.web_console.allowed_ips = Socket.ip_address_list.reduce([]) do |res, addrinfo|
    addrinfo.ipv4? ? res << IPAddr.new(addrinfo.ip_address).mask(24) : res
  end
end
