# This job notifies a Partner that they have a pending distribution
class PartnerMailerJob < ApplicationJob
  def perform(org_id, dist_id, subject, distribution_changes = {})
    current_organization = Organization.find(org_id)
    distribution = Distribution.find(dist_id)
    DistributionMailer.partner_mailer(current_organization, distribution, subject, distribution_changes).deliver_now
  end
end
