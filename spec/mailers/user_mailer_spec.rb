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
end
