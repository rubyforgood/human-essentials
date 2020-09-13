RSpec.describe DistributionMailer, type: :mailer do
  before do
    @organization.default_email_text = "Default email text example"
    @partner = create(:partner, name: 'PARTNER')
    @distribution = create(:distribution, organization: @user.organization, comment: "Distribution comment", partner: @partner)
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

    context "with deliver_method: :pick_up" do
      it "renders the body with 'picked up' specified" do
        distribution = create(:distribution, organization: @user.organization, comment: "Distribution comment", partner: @partner, delivery_method: :pick_up)
        mail = DistributionMailer.partner_mailer(@organization, distribution, 'test subject')
        expect(mail.body.encoded).to match("distribution has been set to be picked up on")
      end
    end

    context "with deliver_method: :delivery" do
      it "renders the body with 'delivered' specified" do
        distribution = create(:distribution, organization: @user.organization, comment: "Distribution comment", partner: @partner, delivery_method: :delivery)
        mail = DistributionMailer.partner_mailer(@organization, distribution, 'test subject')
        expect(mail.body.encoded).to match("distribution has been set to be delivered on")
      end
    end
  end

  describe "#reminder_email" do
    let(:mail) { DistributionMailer.reminder_email(@distribution.id) }

    it "renders the body with organizations email text" do
      expect(mail.body.encoded).to match("This is a friendly reminder")
      expect(mail.subject).to eq("PARTNER Distribution Reminder")
    end

    context "with deliver_method: :pick_up" do
      it "renders the body with 'pick up' specified" do
        distribution = create(:distribution, organization: @user.organization, comment: "Distribution comment", partner: @partner, delivery_method: :pick_up)
        mail = DistributionMailer.reminder_email(distribution.id)
        expect(mail.body.encoded).to match("your distribution pick up date")
      end
    end

    context "with deliver_method: :delivery" do
      it "renders the body with 'delivery' specified" do
        distribution = create(:distribution, organization: @user.organization, comment: "Distribution comment", partner: @partner, delivery_method: :delivery)
        mail = DistributionMailer.reminder_email(distribution.id)
        expect(mail.body.encoded).to match("your distribution delivery date")
      end
    end
  end
end
