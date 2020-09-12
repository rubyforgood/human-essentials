# Provides a preview of a distribution email
class DistributionMailerPreview < ActionMailer::Preview
  def partner_mailer
    DistributionMailer.partner_mailer(Organization.first, Distribution.last, "preview subject")
  end
end