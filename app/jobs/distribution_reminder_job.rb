# This job notifies a Partner that they have a distribution scheduled to be sent in 24 hours
class DistributionReminderJob
  include Sidekiq::Worker

  def perform(dist_id)
    distribution = Distribution.find(dist_id)
    DistributionMailer.delay_until(distribution.issued_at - 1.day).reminder_email(distribution)
  end
end
