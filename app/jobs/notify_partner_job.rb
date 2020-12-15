class NotifyPartnerJob < ApplicationJob
  def perform(request_id)
    request = Request.find_by(id: request_id)

    return unless request

    RequestsConfirmationMailer.confirmation_email(request).deliver_later
  end
end
