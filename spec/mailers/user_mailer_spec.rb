RSpec.describe User, type: :mailer do
  describe "#role_added" do
    let(:user) { create(:user, email: "me@me.com") }
    let(:partner) { create(:partner, name: "Partner 1") }
    let(:mail) { UserMailer.role_added(user, partner, [:partner]) }

    it "renders the body correctly" do
      expect(mail.body.encoded).to match("Partner for Partner 1")
      expect(mail.to).to eq(["me@me.com"])
      expect(mail.subject).to eq("Role Added")
    end
  end

  describe "#send_reset_password_instructions" do
    context "user gets an email with instructions" do
      let(:user) { create(:user) }

      before(:each) do
        user.send_reset_password_instructions
      end

      let(:mail) { ActionMailer::Base.deliveries.last }

      it "sends an email with instructions" do
        expect(mail.body.encoded).to include("For security reasons these invitations expire. This invitation will expire in 8 hours or if a new password reset is triggered.")
      end
    end
  end
end
