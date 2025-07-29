require 'aws-sdk-s3'

desc "Update the development db to what is being used in prod"
BUCKET_NAME = "human-essentials-backups"
PASSWORD_REPLACEMENT = 'password'

task :fetch_latest_db do
  if ENV["RAILS_ENV"] == "production"
    raise "You may not run this backup script in production!"
  end

  backup = fetch_latest_backups

  puts "Recreating databases..."
  system("bin/rails db:environment:set RAILS_ENV=development")
  system("bin/rails db:drop db:create")

  puts "Restoring the database with #{backup.key}"
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
  backups = blob_client.list_objects_v2(bucket: BUCKET_NAME)

  #
  # Retrieve the most up to date version of the DB dump
  #
  backup = backups.contents.select { |b| b.key.match?(".rds.dump") }.sort do |a,b|
    a.last_modified <=> b.last_modified
  end.reverse.first

  #
  # Download each of the backups onto the local disk in tmp
  #
  filepath = fetch_file_path(backup)
  puts "\nDownloading blob #{backup.key} to #{filepath}"
  blob_client.get_object(bucket: BUCKET_NAME, key: backup.key, response_target: filepath)

  #
  # At this point, the dumps should be stored on the local
  # machine of the user under tmp.
  #
  backup
end

def blob_client
  Aws::S3::Client.new(region: 'us-east-2')
end

def fetch_file_path(backup)
  File.join(Rails.root, 'tmp', File.basename(backup.key))
end

def replace_user_passwords
  # Generate the encrypted password so that we can quickly update
  # all users with `update_all`

  u = User.new(password: PASSWORD_REPLACEMENT)
  u.save
  encrypted_password = u.encrypted_password

  User.all.update_all(encrypted_password: encrypted_password)
end
