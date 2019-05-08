# [Super Admin] Users can send the admins feedback messages as they notice them. This is the easiest way to
# gather feedback from users so we can identify when bugs or broken things happen, or receive feature requests.
class Admin::FeedbackMessagesController < AdminController
  def index
    @feedback_messages = FeedbackMessage.all
  end

  def resolve
    message = FeedbackMessage.find(params[:feedback_message_id])
    message.resolved = !message.resolved
    message.save
  end
end
