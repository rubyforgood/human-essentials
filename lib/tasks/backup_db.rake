desc "Update the development db to what is being used in prod"
task :backup_db => :environment do
  system("echo Performing dump of the database.")

  current_time = Time.current.strftime("%Y%m%d%H%M%S")

  system("echo Copying the diaper database...")
  diaper_backup_filename = "#{current_time}_diaper.dump"
  system("PGPASSWORD=#{ENV["DIAPER_DB_PASSWORD"]} pg_dump -Fc -v --host=#{ENV["DIAPER_DB_HOST"]} --username=#{ENV["DIAPER_DB_USERNAME"]} --dbname=#{ENV["DIAPER_DB_DATABASE"]} -f #{diaper_backup_filename}")

  system("echo Copying the partner database...")
  partner_backup_filename = "#{current_time}_partner.dump"
  system("PGPASSWORD=#{ENV["PARTNER_DB_PASSWORD"]} pg_dump -Fc -v --host=#{ENV["PARTNER_DB_HOST"]} --username=#{ENV["PARTNER_DB_USERNAME"]} --dbname=#{ENV["PARTNER_DB_DATABASE"]} -f #{partner_backup_filename}")

  account_name = ENV["AZURE_STORAGE_ACCOUNT_NAME"]
  account_key = ENV["AZURE_STORAGE_ACCESS_KEY"]

  blob_client = Azure::Storage::Blob::BlobService.create(
    storage_account_name: account_name,
    storage_access_key: account_key
  )

  [diaper_backup_filename, partner_backup_filename].each do |backup_name|
    system("echo Uploading #{backup_name}")
    blob_client.create_block_blob("backups", backup_name, File.read(backup_name))
  end
end
