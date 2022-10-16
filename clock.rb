require "rake"
require "clockwork"
require "clockwork/database_events"
require_relative "./config/boot"
require_relative "./config/environment"

module Clockwork
  handler do |job|
    puts "Running #{job}"
  end

  every(1.day, at: '00:00', "Periodically reset seed data in staging") do
    unless ENV['RAILS_ENV'] == 'staging'
      rake = Rake.application
      rake.init
      rake.load_rakefile
      rake["reset_demo"].invoke
    end
  end
end
