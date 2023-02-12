class PartnerMailer < ApplicationMailer
  default from: "Please do not reply to this email as this mail box is not monitored — Human Essentials <no-reply@humanessentials.app>"

  def recertification_request(partner:)
    @partner = partner
    @organization = partner.organization

    mail to: partner.email, subject: "[Action Required] Please Update Your Agency Information"
  end

  def application_approved(partner:)
    @partner = partner
    @organization = partner.organization

    mail to: partner.email, subject: "Application Approved"
  end
end
