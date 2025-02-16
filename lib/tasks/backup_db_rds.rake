require 'aws-sdk-s3'

desc "Update the development db to what is being used in prod"
task :backup_db_rds => :environment do
  logger = Logger.new(STDOUT)
  logger.info("Performing dump of the database.")

  current_time = Time.current.strftime("%Y%m%d%H%M%S")

  logger.info("Copying the database...")
  backup_filename = "#{Rails.env}-#{current_time}.rds.dump"
  system("PGPASSWORD='#{ENV["DIAPER_DB_PASSWORD"]}' pg_dump -Fc -v --host=#{ENV["DIAPER_DB_HOST"]} --username=#{ENV["DIAPER_DB_USERNAME"]} --dbname=#{ENV["DIAPER_DB_DATABASE"]} -f #{backup_filename}")

  client = Aws::S3::Client.new

  logger.info("Uploading #{backup_filename}")
  client.put_object(bucket: "human-essentials-backups", key: "backups/#{backup_filename}", body: File.read(backup_filename))
  File.delete(backup_filename)
end
