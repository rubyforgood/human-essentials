# This job notifies a Partner that they have a distribution scheduled to be sent in 24 hours
class DistributionReminder
  class << self
    def perform(dist_id)
      distribution = Distribution.find_by(id: dist_id)

      # NOTE: This is being also checked in the DistributionMailer itself
      return unless send_reminder?(distribution)

      DistributionMailer.delay_until(distribution.issued_at - 1.day).reminder_email(distribution.id)
    end

    private

    def send_reminder?(distribution)
      !(distribution.nil? || distribution.past? || !distribution.partner.send_reminders)
    end
  end
end

