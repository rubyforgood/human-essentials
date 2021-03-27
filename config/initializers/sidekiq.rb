require 'sidekiq'
require 'sidekiq-scheduler'

# Added this ENV variable to prevent sending double  reminders via
# ReminderDeadlineJob scheduled whilst  two versions of production
# are being hosted. We will have a time period were we will be hosting
# this on azure and heroku.
#
# We will be removing this entire sidekiq scheduler in favor of a rake task
# eventually that we'll run in herokus scheduler.
# More details written in https://github.com/rubyforgood/diaper/issues/2204
Sidekiq::Scheduler.enabled = ENV["DISABLE_SIDEKIQ_SCHEDULER"] ? false : true
Sidekiq.schedule = YAML.load_file(File.expand_path(Rails.root + 'config/scheduler.yml', __FILE__))
SidekiqScheduler::Scheduler.load_schedule!
Sidekiq::Extensions.enable_delay!

#
# Added this conditional to run the async jobs immediately
# in development. This allows us to see the results of
# enqueuing a mailer job instantly.
#
# This effectively turns .deliver_later to .deliver_now in
# the development environment.
#
# Refer to https://makandracards.com/makandra/28125-perform-sidekiq-jobs-immediately-in-development
# for context and details.
if Rails.env.development?
  require 'sidekiq/testing'
  Sidekiq::Testing.inline!
end
