desc "This task is called by the Heroku scheduler add-on to reset the demo periodically at everyday"
task :reset_demo => :environment do
  puts "Cleaning up the partner database..."
  DatabaseCleaner[:active_record, { model: Partners::Base }]
  DatabaseCleaner.strategy = :truncation
  DatabaseCleaner.clean

  puts "Cleaning up the diaper database..."
  DatabaseCleaner[:active_record, { model: ApplicationRecord }]
  DatabaseCleaner.strategy = :truncation
  DatabaseCleaner.clean

  puts "Seeding the databases again..."
  Rake::Task["db:seed"].invoke

  puts "Done!"
end
