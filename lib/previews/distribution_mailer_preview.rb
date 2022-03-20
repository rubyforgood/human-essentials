# Provides a preview of a distribution email
class DistributionMailerPreview < ActionMailer::Preview
  def partner_mailer
    DistributionMailer.partner_mailer(Organization.first, Distribution.last, 'Your Distribution', {})
  end

  def reminder_email
    DistributionMailer.reminder_email(Distribution.last.id)
  end
end
