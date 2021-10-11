class NotifyPartnerJob < ApplicationJob
  def perform(request_id)
    request = Request.find_by(id: request_id)

    RequestsConfirmationMailer.confirmation_email(request).deliver_later if valid?(request)
  end

  private

  def valid?(request)
    request && !request.partner.deactivated?
  end
end
