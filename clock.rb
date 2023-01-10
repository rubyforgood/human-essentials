require "rake"
require "clockwork"
require "clockwork/database_events"
require_relative "./config/boot"
require_relative "./config/environment"

module Clockwork
  handler do |job|
    puts "Running #{job}"
  end

  every(1.day, "Periodically reset seed data in staging", at: "00:00") do
    if ENV["RAILS_ENV"] == "staging"
      rake = Rake.application
      rake.init
      rake.load_rakefile
      rake["reset_demo"].invoke
    end
  end
end
