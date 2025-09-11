require "aws-sdk-s3"

# to be called from Clock
module BackupDbRds
  def self.run
    logger = Logger.new($stdout)
    logger.info("Performing dump of the database.")

    current_time = Time.current.strftime("%Y%m%d%H%M%S")

    logger.info("Copying the database...")
    backup_filename = "#{current_time}.rds.dump"
    system("PGPASSWORD='#{ENV["DIAPER_DB_PASSWORD"]}' pg_dump -Fc -v --host=#{ENV["DIAPER_DB_HOST"]} --username=#{ENV["DIAPER_DB_USERNAME"]} --dbname=#{ENV["DIAPER_DB_DATABASE"]} -f #{backup_filename}")

    client = Aws::S3::Client.new(region: "us-east-2")

    logger.info("Uploading #{backup_filename}")
    client.put_object(key: "backups/#{backup_filename}",
      body: File.read(backup_filename),
      bucket: "human-essentials-backups")

    Dir.glob(Rails.root.join("*.rds.dump")).each do |file|
      File.delete(file)
    end
  end
end
