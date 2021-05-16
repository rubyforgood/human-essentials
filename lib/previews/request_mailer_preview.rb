class RequestMailerPreview < ActionMailer::Preview
  def request_cancel_partner_notification
    RequestMailer.request_cancel_partner_notification(request_id: Request.last.id)
  end
end
