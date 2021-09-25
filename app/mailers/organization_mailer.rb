class OrganizationMailer < ApplicationMailer
  default from: "info@humanessentials.app"

  def partner_approval_request(organization:, partner:)
    @partner = partner
    @organization = organization

    mail to: @organization.email, subject: "[Action Required] Approval requested for #{@partner.name}"
  end
end
