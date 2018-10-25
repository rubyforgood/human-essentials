class DistributionMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.distribution_mailer.partner_mailer.subject
  #
  def partner_mailer(current_organization, distribution)
    @partner = distribution.partner
    @distribution = distribution
    attachments[format("%s %s.pdf", @partner.name, @distribution.created_at.strftime("%Y-%m-%d"))] = DistributionPdf.new(current_organization, @distribution).render
    mail(to: @partner.email, from: current_organization.email, subject: "Your Distribution")
  end
end
