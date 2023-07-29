require 'rufus-scheduler'

scheduler = Rufus::Scheduler.singleton

scheduler.cron '0 3 * * *' do
  system('bundle exec rake cache_historical_data')
end
