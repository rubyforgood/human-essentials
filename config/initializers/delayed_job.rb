Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 60
Delayed::Worker.max_attempts = 3
Delayed::Worker.max_run_time = 20.minutes
Delayed::Worker.read_ahead = 10
Delayed::Worker.delay_jobs = !Rails.env.test?
Delayed::Worker.raise_signal_exceptions = :term
Delayed::Worker.logger = ActiveSupport::Logger.new(STDOUT)

# https://github.com/rubyforgood/human-essentials/issues/4065
Delayed::Worker.default_queue_name = 'default'
Delayed::Worker.queue_attributes = {
  # bigger number is lower priority
  "low_priority" => { priority: 10 } 
}
