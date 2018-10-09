class DistributionMailer < ApplicationMailer

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.distribution_mailer.partner_mailer.subject
  #
  def partner_mailer(email)
    @greeting = "Hi"

    mail to: "to@example.org"
  end
end
