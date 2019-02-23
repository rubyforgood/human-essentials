class PartnerMailerJob < ActiveJob::Base
  queue_as :default

  def perform(current_organization, distribution)
    DistributionMailer.partner_mailer(current_organization, distribution).deliver_now
  end
end
