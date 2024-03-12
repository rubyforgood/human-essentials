class OrganizationMailer < ApplicationMailer
  default from: "Please do not reply to this email as this mail box is not monitored — Human Essentials <no-reply@humanessentials.app>"

  def partner_approval_request(organization:, partner:)
    @partner = partner
    @organization = organization

    mail to: @organization.email, subject: "[Action Required] Approval requested for #{@partner.name}"
  end

    def request_submission_notification(organization:, partner:)
    @partner = partner
    @organization = organization

    # Assuming the attribute to determine email opt-in is `email_notification_opt_in`
    if @organization.email_notification_opt_in?  # Check if email notification is opted in
      # Send email to the bank's contact email
      mail to: @organization.contact_email, subject: "New Request Submitted by #{@partner.name}"
    end
  end
end
