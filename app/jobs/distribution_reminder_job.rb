# This job notifies a Partner that they have a distribution scheduled to be sent in 24 hours
class DistributionReminderJob
    include Sidekiq::Worker

    def perform(dist_id)
    #   current_organization = Organization.find(org_id)
      distribution = Distribution.find(dist_id)
      DistributionMailer.reminder_email(distribution).deliver_now
    end
  end
