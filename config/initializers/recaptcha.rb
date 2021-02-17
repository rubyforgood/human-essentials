# See https://github.com/ambethia/recaptcha for details on configuring

Recaptcha.configure do |config|
  config.site_key   = ENV["RECAPTCHA_SITE_KEY"]
  config.secret_key = ENV["RECAPTCHA_PRIVATE_KEY"]

  # To disable requiring (OR rendering) Recaptcha in a particular env,
  # add that env to the config.skip_verify_env array. E.g.,
  #
  #   config.skip_verify_env.push("some_environment")
  #
  # By default, this array already contains "test" and "cucumber"
end
