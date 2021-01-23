class NotifyPartnerJob < ApplicationJob
  def perform(request_id)
    request = Request.find_by(id: request_id)

    RequestsConfirmationMailer.confirmation_email(request).deliver_later if request
  end
end
