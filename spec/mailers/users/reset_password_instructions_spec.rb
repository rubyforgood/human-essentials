RSpec.describe "User Reset Password Instructions", type: :mailer do
  describe "#send_reset_password_instructions" do
    context "user gets an email with instructions" do
      let(:user) { create(:user) }

      before(:each) do
        user.send_reset_password_instructions
      end

      let(:mail) { ActionMailer::Base.deliveries.last }

      it "sends an email with instructions" do
        expect(mail.body.encoded).to include("Someone has requested a link to change your password. You can do this through the link below.")
        expect(mail.body.encoded).to include("For security reasons these invites expire. This reset will expire in 8 hours or if a new password reset is triggered.")
        expect(mail.body.encoded).to include('If your invitation has an expired message, go <a href="http://localhost/users/password/new">here</a> and enter your email address to receive a new invite')
        expect(mail.body.encoded).to include("If you didn't request this, please ignore this email.")
        expect(mail.body.encoded).to include("Your password won't change until you access the link above and create a new one.")
      end
    end
  end
end
