# frozen_string_literal: true
Kaminari.configure do |config|
  if Rails.env.development? || Rails.env.staging?
    config.default_per_page = 5
  else
    config.default_per_page = 50
  end
  # config.max_per_page = nil
  # config.window = 4
  # config.outer_window = 0
  # config.left = 0
  # config.page_method_name = :page
  # config.param_name = :page
  # config.params_on_first_page = false
end
