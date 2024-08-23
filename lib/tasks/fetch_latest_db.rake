desc "Update the development db to what is being used in prod"
BACKUP_CONTAINER_NAME = 'backups'
PASSWORD_REPLACEMENT = 'password'

task :fetch_latest_db do
  if ENV["RAILS_ENV"] == "production"
    raise "You may not run this backup script in production!"
  end

  backup = fetch_latest_backups

  puts "Recreating databases..."
  system("bin/rails db:environment:set RAILS_ENV=development")
  system("bin/rails db:drop db:create")

  puts "Restoring the database with #{backup.name}"
  backup_filepath = fetch_file_path(backup)
  db_username = ENV["PG_USERNAME"].presence || ENV["USER"].presence || "postgres"
  db_host = ENV["PG_HOST"].presence || "localhost"
  db_password = ENV["PG_PASSWORD"].presence
  system("PGPASSWORD='#{db_password}' pg_restore --clean --no-acl --no-owner -h #{db_host} -d diaper_dev -U #{db_username} #{backup_filepath}")

  puts "Done!"

  # Update the ar_internal_metadata table to have the correct environment
  # This is needed because attempting to drop the development DB will
  # raise a protected environment error.
  system("bin/rails db:environment:set RAILS_ENV=development")

  # Clear out the job queue so that you aren't running jobs in the local
  # environment.
  system("bin/rails jobs:clear")

  puts "Replacing all the passwords with the replacement for ease of use: '#{PASSWORD_REPLACEMENT}'"
  system("bin/rails db:replace_user_passwords")

  puts "DONE!"
end

namespace :db do
  desc "Replace all user passwords with the replacement password"
  task :replace_user_passwords => :environment do
    if Rails.env.production?
      raise "You may not run this backup script in production!"
    end

    replace_user_passwords
  end
end

private

def fetch_latest_backups
  backups = blob_client.list_blobs(BACKUP_CONTAINER_NAME)

  #
  # Retrieve the most up to date version of the DB dump
  #
  backup = backups.select { |b| b.name.match?(".dump") }.sort do |a,b|
    Time.parse(a.properties[:last_modified]) <=> Time.parse(b.properties[:last_modified])
  end.reverse.first

  #
  # Download each of the backups onto the local disk in tmp
  #
  filepath = fetch_file_path(backup)
  puts "\nDownloading blob #{backup.name} to #{filepath}"
  blob, content = blob_client.get_blob(BACKUP_CONTAINER_NAME, backup.name)
  File.open(filepath, "wb") { |f| f.write(content)  }

  #
  # At this point, the dumps should be stored on the local
  # machine of the user under tmp.
  #
  return backup
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
end
