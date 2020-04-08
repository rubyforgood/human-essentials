# This job notifies a Partner that they have a distribution scheduled to be sent in 24 hours
class DistributionReminder
  def self.perform(dist_id)
    distribution = Distribution.find_by(id: dist_id)

    # NOTE: This is being also checked in the DistributionMailer itself
    return if distribution.nil? || distribution.past? || !distribution.partner.send_reminders

    DistributionMailer.delay_until(distribution.issued_at - 1.day).reminder_email(distribution)
  end
end

