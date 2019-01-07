class FeedbackMessageController < ApplicationController
  def create
    @feedback_message = FeedbackMessage.new(feedback_message_params)
    @feedback_message.user_name = current_user.name
    @feedback_message.user_id = current_user.id
    @feedback_message.user_email = current_user.email
    @feedback_message.path = request.referer
    @feedback_message.timestamp = DateTime.current
    FeedbackMessageMailer.feedback_email(@feedback_message).deliver_now
    flash[:notice] = "Your feedback has been logged!"
    redirect_to request.referer
  end

  private

  def feedback_message_params
    params.require(:feedback_message).permit(:message)
  end
end
