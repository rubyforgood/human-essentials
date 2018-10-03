class PartnerMailerJob
  include SuckerPunch::Job
  workers 2


  def perform(current_organization, distribution)
    DistributionMailer.partner_mailer(current_organization, distribution)
  end
end
