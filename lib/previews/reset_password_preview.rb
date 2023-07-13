class ResetPasswordPreview < ActionMailer::Preview
  def user_invitation
    User.first.send_reset_password_instructions
  end
end
