namespace :database do
  desc "Upload rails database.yml configuration file to web server"
  task config: :environment do
    on roles(:web) do
      config_file = File.expand_path("../templates/database.yml.erb", __dir__)
      config = ERB.new(File.read(config_file)).result(binding)
      upload! StringIO.new(config), "/tmp/database.yml"
      arguments = :cp, "/tmp/database.yml", "#{shared_path}/config/database.yml"
      execute(*arguments)
    end
  end
end

