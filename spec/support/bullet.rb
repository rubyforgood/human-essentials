# frozen_string_literal: true

require "bullet"

Bullet.enable = true
Bullet.raise = true
Bullet.bullet_logger = false
Bullet.console = false

RSpec.configure do |config|
  config.before(:each) { Bullet.start_request }
  config.after(:each) do
    Bullet.perform_out_of_channel_notifications if Bullet.notification?
    Bullet.end_request
  end
end
