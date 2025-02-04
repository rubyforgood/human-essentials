class RequestsConfirmationMailerPreview < ActionMailer::Preview
  def confirmation_email_with_requester
    RequestsConfirmationMailer.confirmation_email(Request.last)
  end

  def confirmation_email_without_requester
    request = Request.last
    request.partner_user_id = nil
    RequestsConfirmationMailer.confirmation_email(request)
  end
end
