# This mailer is for correspondence about Distributions; primarily for notifying Partners about pending distributions
class DistributionMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.distribution_mailer.partner_mailer.subject
  #
  def partner_mailer(current_organization, distribution, subject)
    @partner = distribution.partner
    @distribution = distribution
    @default_email_text = current_organization.default_email_text
    @comment = distribution.comment
    @from_email = current_organization.email.presence || current_organization.users.first.email
    attachments[format("%s %s.pdf", @partner.name, @distribution.created_at.strftime("%Y-%m-%d"))] = DistributionPdf.new(current_organization, @distribution).render
    mail(to: @partner.email, from: @from_email, subject: "#{subject} from #{current_organization.name}")
  end

  def reminder_email(distribution)
    @partner = distribution.partner
    @distribution = distribution
    mail(to: @partner.email, from: @distribution.organization.email, subject: "#{@partner.name} Distribution Reminder")
  end
end
