# organization.rb
class Organization < ApplicationRecord
  def send_submission_notification(partner)
    OrganizationMailer.request_submission_notification(organization: self, partner: partner).deliver_now if email_notification_opt_in?
  end
end

# organization_mailer.rb
class OrganizationMailer < ApplicationMailer
  default from: "Please do not reply to this email as this mail box is not monitored — Human Essentials <no-reply@humanessentials.app>"

    def partner_approval_request(organization:, partner:)
    @partner = partner
    @organization = organization

    mail(to: @organization.contact_email, subject: "New Request Submitted by #{@partner.name}")
  end
end
