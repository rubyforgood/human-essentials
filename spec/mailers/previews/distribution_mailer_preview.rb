# Preview all emails at http://localhost:3000/rails/mailers/distribution_mailer
class DistributionMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/distribution_mailer/partner_mailer
  def partner_mailer
    DistributionMailerMailer.partner_mailer
  end

end
