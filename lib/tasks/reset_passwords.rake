desc "reset passwords"
PASSWORD_REPLACEMENT = 'password'

task :reset_passwords => :environment do

  puts "Replacing all the passwords with the replacement for ease of use: '#{PASSWORD_REPLACEMENT}'"
  replace_user_passwords

  puts "DONE!"
end

private

def replace_user_passwords
  # Generate the encrypted password so that we can quickly update
  # all users with `update_all`

  u = User.new(password: PASSWORD_REPLACEMENT)
  u.save
  encrypted_password = u.encrypted_password

  User.all.update_all(encrypted_password: encrypted_password)
end