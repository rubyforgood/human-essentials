# config valid only for current version of Capistrano
lock "3.14.1"

set :repo_url,        "git@github.com:rubyforgood/diaper.git"
set :application,     "diaper_base"
set :user,            "deploy"
set :puma_threads,    [4, 16]
set :puma_workers,    0
set :ssh_options, keys: ["config/deploy_id_rsa_enc"] if File.exist?("config/deploy_id_rsa_enc")

# Don't change these unless you know what you're doing
set :pty,             false
set :use_sudo,        false
# set :stage,           :production
set :deploy_via,      :remote_cache
set :deploy_to,       "/home/#{fetch(:user)}/apps/#{fetch(:application)}"
set :puma_bind,       "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}-puma.sock"
set :puma_state,      "#{shared_path}/tmp/pids/puma.state"
set :puma_pid,        "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.error.log"
set :puma_error_log,  "#{release_path}/log/puma.access.log"
set :ssh_options,     forward_agent: true, user: fetch(:user), keys: %w(~/.ssh/id_rsa.pub)
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true # Change to false when not using ActiveRecord
set :sidekiq_processes, 2

## Defaults:
# set :scm,           :git
set :branch do
  if ENV["TAG"] && ENV["BRANCH"]
    raise "You can only specify either TAG or BRANCH"
  elsif ENV["TAG"]
    ENV["TAG"]
  elsif ENV["BRANCH"]
    ENV["BRANCH"]
  end
end
# set :format,        :pretty
# set :log_level,     :debug
# set :keep_releases, 5

## Linked Files & Directories (Default None):
set :linked_files, %w{config/database.yml config/master.key .env.production}
set :linked_dirs,  %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system storage}

namespace :puma do
  desc "Create Directories for Puma Pids and Socket"
  task :make_dirs do
    on roles(:app) do
      execute "mkdir #{shared_path}/tmp/sockets -p"
      execute "mkdir #{shared_path}/tmp/pids -p"
    end
  end

  before :start, :make_dirs
end

namespace :deploy do
  desc "Make sure local git is in sync with remote."
  task :check_revision do
    on roles(:app) do
      if fetch(:branch).nil?
        puts "You must provide either a TAG or a BRANCH. Example: 'TAG=2.2.0 cap <environment> deploy'"
        exit
      end
    end
  end

  desc "Restart application"
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      invoke "puma:restart"
    end
  end

  desc "Puma is sometimes not restarting. This ensures it restarts... Nothing happens if restart works"
  task :ensure_start do
    on roles(:app), in: :sequence, wait: 10 do
      invoke "puma:stop"
    end
  end

  before :starting,     :check_revision
  after  :finishing,    :compile_assets
  after  :finishing,    :cleanup
  after  :finishing,    :ensure_start
end

# ps aux | grep puma    # Get puma pid
# kill -s SIGUSR2 pid   # Restart puma
# kill -s SIGTERM pid   # Stop puma
