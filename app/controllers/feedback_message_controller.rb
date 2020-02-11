# Users can only write messages, they cannot read any messages, even their own.
class FeedbackMessageController < ApplicationController
  def create
    @feedback_message = FeedbackMessage.new(feedback_message_params)
    @feedback_message.user = current_user
    @feedback_message.path = request.referer
    @feedback_message.save
    @feedback_message.reload
    FeedbackMessageMailer.feedback_email(@feedback_message).deliver_now
    flash[:notice] = "Your feedback has been logged!"
    redirect_to request.referer
  end

  private

  def feedback_message_params
    params.require(:feedback_message).permit(:message)
  end
end
