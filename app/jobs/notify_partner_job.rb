class NotifyPartnerJob < ApplicationJob
  def perform(request_id)
    request = Request.find(request_id)

    RequestsConfirmationMailer.confirmation_email(request).deliver_later
  end
end
