task :kill_postgres_connections => :environment do
  db_name = Rails.configuration.database_configuration[Rails.env]['database']
  sh = <<EOF
ps xa \
  | grep postgres: \
  | grep #{db_name} \
  | grep -v grep \
  | awk '{print $1}' \
  | sudo xargs kill
EOF
  puts `#{sh}`
  puts "Done killing the connections!"
end

task "db:drop" => :kill_postgres_connections