RSpec.describe DistributionMailer, type: :mailer do
  before do
    @organization.default_email_text = "Default email text example"
    partner = create(:partner, name: 'PARTNER')
    @distribution = create(:distribution, organization: @user.organization, comment: "Distribution comment", partner: partner)
  end

  describe "#partner_mailer" do
    let(:mail) { DistributionMailer.partner_mailer(@organization, @distribution, 'test subject') }

    it "renders the body with organizations email text" do
      expect(mail.body.encoded).to match("Default email text example")
      expect(mail.subject).to eq("test subject from DEFAULT")
    end

    it "renders the body with distributions text" do
      expect(mail.body.encoded).to match("Distribution comment")
      expect(mail.subject).to eq("test subject from DEFAULT")
    end
  end

  describe "#reminder_email" do
    let(:mail) { DistributionMailer.reminder_email(@distribution.id) }

    it "renders the body with organizations email text" do
      expect(mail.body.encoded).to match("This is a friendly reminder")
      expect(mail.subject).to eq("PARTNER Distribution Reminder")
    end
  end
end
