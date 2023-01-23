class OrganizationMailer < ApplicationMailer
  default from: "Please do not reply to this email as this mail box is not monitored — Human Essentials <no-reply@humanessentials.app>"

  def partner_approval_request(organization:, partner:)
    @partner = partner
    @organization = organization

    mail to: @organization.email, subject: "[Action Required] Approval requested for #{@partner.name}"
  end
end
