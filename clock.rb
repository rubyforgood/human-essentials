require "rake"
require "clockwork"
require "clockwork/database_events"
require_relative "config/boot"
require_relative "config/environment"

module Clockwork
  handler do |job|
    puts "Running #{job}"
  end

  # The nightly "Cache historical data" job is gone, and so is HistoricalDataCacheJob.
  #
  # It wrote `"#{org}-historical-#{type}-data"`, and once the trend pages gained a date range the
  # page read a key built from the window instead -- so the job spent every night, for every active
  # organization and three record types, writing something nothing read. Verified before removing:
  # the only other reference to that key was the job's own spec.
  #
  # The page caches its own figures for five minutes, which is measured at 6ms to compute on this
  # data. A pre-warm that survives until morning would have to hold the figures for a day, and a
  # day-old inventory report is the staleness the page used to apologise for.

  every(1.day, "Periodically reset seed data in staging", at: "01:00") do
    if ENV["RAILS_ENV"] == "staging"
      rake = Rake.application
      rake.init
      rake.load_rakefile
      rake["reset_demo"].invoke
    end
  end

  every(4.hours, "Backup prod DB to Azure blob storage", if: lambda { |_| Rails.env.production? }) do
    BackupDbRds.run
  end

  every(1.day, "Send reminder emails", at: "12:00", if: lambda { |_| Rails.env.production? }) do
    ReminderDeadlineJob.perform_later
  end
end
