require 'sidekiq'
require 'sidekiq-scheduler'

Sidekiq::Scheduler.enabled = true
Sidekiq.schedule = YAML.load_file(File.expand_path(Rails.root+'config/scheduler.yml', __FILE__))
SidekiqScheduler::Scheduler.load_schedule!
Sidekiq::Extensions.enable_delay!