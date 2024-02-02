require "rake"
require "clockwork"
require "clockwork/database_events"
require_relative "config/boot"
require_relative "config/environment"

module Clockwork
  handler do |job|
    puts "Running #{job}"
  end

  DATA_TYPES = %w[Distribution Purchase Donation]
  every(1.day, "Cache historical data", at: "03:00") do
    Organization.is_active.each do |org|
      DATA_TYPES.each do |type|
        Rails.logger.info("Queuing up #{type} cache data for #{org.name}")
        HistoricalDataCacheJob.perform_later(org_id: org.id, type: type)
      end
    end

    Rails.logger.info("Done!")
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
