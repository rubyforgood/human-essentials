class PartnerMailerJob
  include Sidekiq::Worker

  def perform(current_organization, distribution)
    DistributionMailer.partner_mailer(current_organization, distribution).deliver_now if Rails.env.production?
  end
end
