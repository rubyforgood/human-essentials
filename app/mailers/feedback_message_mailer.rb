class FeedbackMessageMailer < ApplicationMailer
  def feedback_email(feedback_message)
    @feedback_message = feedback_message
    mail(to: "accounts@diaper.app", subject: "SITE FEEDBACK")
  end
end
