class PartnerMailer < ApplicationMailer
  default from: "info@diaper.app"

  def recertification_request(partner:)
    @partner = partner

    mail to: partner.email, subject: "[Action Required] Please Update Your Agency Information"
  end
end
