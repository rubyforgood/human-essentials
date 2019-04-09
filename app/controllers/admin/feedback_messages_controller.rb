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
