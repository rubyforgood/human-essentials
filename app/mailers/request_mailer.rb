class RequestMailer < ApplicationMailer
  def request_cancel_partner_notification(request_id:)
    @request ||= Request.find(request_id)
    @organization ||= @request.organization
    @partner = @request.partner

    mail(
      to: @partner.email,
      subject: "Request Cancelation Notice"
    )
  end
end
