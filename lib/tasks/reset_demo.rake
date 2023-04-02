desc "Resets the database to default demo data"
task :reset_demo => :environment do
  raise "Cannot run this in production" if Rails.env.production?

  puts "Cleaning up the database..."
  DatabaseCleaner[:active_record].strategy = :truncation
  DatabaseCleaner.clean

  puts "Seeding the databases again..."
  Rake::Task["db:seed"].invoke

  puts "Done!"
end
