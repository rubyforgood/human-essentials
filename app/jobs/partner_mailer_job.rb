class PartnerMailerJob
  include Sidekiq::Worker

  def perform(org_id, dist_id)
    current_organization = Organization.find(org_id)
    distribution = Distribution.find(dist_id)
    DistributionMailer.partner_mailer(current_organization, distribution).deliver_now if Rails.env.production?
  end
end
