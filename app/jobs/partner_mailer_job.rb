class PartnerMailerJob < ActiveJob::Base
  workers 2

  def perform(current_organization, distribution)
    DistributionMailer.partner_mailer(current_organization, distribution).deliver_now
  end
end
