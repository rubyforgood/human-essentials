require 'rufus-scheduler'

scheduler = Rufus::Scheduler.singleton

# TODO: Re-enable this on production once we figure out why it's running nonstop.

if ENV['ENABLE_HISTORICAL_CACHE_JOB'] == 'true'
  scheduler.cron '0 3 * * *' do
    system('bundle exec rake cache_historical_data')
  end
end
