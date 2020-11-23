Recaptcha.configure do |config|
  config.site_key   = Rails.application.secrets[:RECAPTCHA_PUBLIC_KEY]
  config.secret_key = Rails.application.secrets[:RECAPTCHA_PRIVATE_KEY]
end
