# This job notifies a Partner that they have a pending distribution
class PartnerMailerJob
  include Sidekiq::Worker

  def perform(org_id, dist_id, subject)
    current_organization = Organization.find(org_id)
    distribution = Distribution.find(dist_id)
    DistributionMailer.partner_mailer(current_organization, distribution, subject).deliver_now
  end
end
