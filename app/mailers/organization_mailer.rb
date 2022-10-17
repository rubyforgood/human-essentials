class OrganizationMailer < ApplicationMailer
  default from: "no-reply@humanessentials.app"

  def partner_approval_request(organization:, partner:)
    @partner = partner
    @organization = organization

    mail to: @organization.email, subject: "[Action Required] Approval requested for #{@partner.name}"
  end
end
