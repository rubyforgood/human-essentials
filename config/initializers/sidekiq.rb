require 'sidekiq'
require 'sidekiq-scheduler'

Sidekiq::Scheduler.enabled = true
Sidekiq.schedule = YAML.load_file(File.expand_path('../../scheduler.yml', __FILE__))
SidekiqScheduler::Scheduler.load_schedule!