desc "Update the development db to what is being used in prod"
BACKUP_CONTAINER_NAME = 'backups'
PASSWORD_REPLACEMENT = 'password'

task :fetch_latest_db => :environment do
  diaper_backup, partner_backup = fetch_latest_backups

  puts "Recreating databases..."
  system("rails db:drop db:create db:migrate")

  puts "Restoring the diaper_dev database with #{diaper_backup.name}..."
  diaper_backup_filepath = fetch_file_path(diaper_backup)
  system("pg_restore --clean --no-acl --no-owner -h localhost -d diaper_dev #{diaper_backup_filepath}")
  puts "Done! Next up is the partner database"

  puts "Restoring the diaper_dev database with #{partner_backup.name}..."
  partner_backup_filepath = fetch_file_path(partner_backup)
  system("pg_restore --clean --no-acl --no-owner -h localhost -d partner_dev #{partner_backup_filepath}")
  puts "Done and... done!"

  puts "Replacing all the passwords with the replacement: '#{PASSWORD_REPLACEMENT}'"
  replace_user_passwords

  puts "DONE!"
end

private

def fetch_latest_backups
  backups = blob_client.list_blobs(BACKUP_CONTAINER_NAME)

  #
  # Retrieve the most up to date versions of the DB dump
  #
  latest_partner_backup = backups.select { |b| b.name.match?("partner.dump") }.sort do |a,b|
    Time.parse(a.properties[:last_modified]) <=> Time.parse(b.properties[:last_modified])
  end.reverse.first

  latest_diaper_backup = backups.select { |b| b.name.match?("diaper.dump") }.sort do |a,b|
    Time.parse(a.properties[:last_modified]) <=> Time.parse(b.properties[:last_modified])
  end.reverse.first

  #
  # Download each of the backups onto the local disk in tmp
  #
  [latest_diaper_backup, latest_partner_backup].each do |backup|
    filepath = fetch_file_path(backup)
    puts "\nDownloading blob #{backup.name} to #{filepath}"
    blob, content = blob_client.get_blob(BACKUP_CONTAINER_NAME, backup.name)
    File.open(filepath, "wb") { |f| f.write(content)  }
  end

  #
  # At this point, the dumps should be stored on the local
  # machine of the user under tmp.
  #
  return latest_diaper_backup, latest_partner_backup
end

def blob_client
  return @blob_client if @blob_client

  account_name = ENV["AZURE_STORAGE_ACCOUNT_NAME"]
  account_key = ENV["AZURE_STORAGE_ACCESS_KEY"]

  if account_name.blank? || account_key.blank?
    raise "You must have the correct azure credentials in your ENV"
  end

  @blob_client = Azure::Storage::Blob::BlobService.create(
    storage_account_name: account_name,
    storage_access_key: account_key
  )
end

def fetch_file_path(backup)
  File.join(Rails.root, 'tmp', backup.name)
end

def replace_user_passwords
  # Generate the encrypted password so that we can quickly update
  # all users with `update_all`

  u = User.new(password: PASSWORD_REPLACEMENT)
  u.save
  encrypted_password = u.encrypted_password

  User.all.update_all(encrypted_password: encrypted_password)
  Partners::User.all.update_all(encrypted_password: encrypted_password)
end
