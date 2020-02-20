namespace :nginx do
  desc "Upload nginx configuration file to web server"
  task config: :environment do
    on roles(:web) do
      config_file = File.expand_path("../templates/nginx.conf.erb", __dir__)
      config = ERB.new(File.read(config_file)).result(binding)
      upload! StringIO.new(config), "/tmp/nginx.conf"
      arguments = :sudo, :mv, "/tmp/nginx.conf", "/etc/nginx/sites-available/#{fetch(:application)}"
      execute(*arguments)
    end
  end
end
