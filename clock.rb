require "clockwork"
require File.expand_path("../config/environment", __FILE__)
include Clockwork

every(1.day, "Reset staging demo seed", at: "01:30") do
  if Rails.env.staging?
    `rails reset_demo`
  end
end
