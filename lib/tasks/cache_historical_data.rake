desc "This task is run by a scheduling tool nightly to cache the processor intensive queries"
task :cache_historical_data => :environment do
  puts "Caching historical data"
  DATA_TYPES = ['Distribution', 'Purchase', 'Donation']

  orgs = Organization.all

  orgs.each do |org|
    DATA_TYPES.each do |type|
      puts "Queuing up #{type} cache data for #{org.name}"
      HistoricalDataCacheJob.perform_later(org_id: org.id, type: type)
    end
  end
  
  puts "Done!"
end
