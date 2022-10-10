RSpec.describe PartnerMailer, type: :mailer do
  describe "#recertification_request" do
    subject { PartnerMailer.recertification_request(partner: partner) }
    let(:partner) { create(:partner) }

    it "renders the body with text that indicates to recertify and link to where" do
      expect(subject.body.encoded).to include("Hi #{partner.name}")
      expect(subject.body.encoded).to include("It's time to update your agency information!")
      expect(subject.body.encoded).to include("Please log in to your account at #{new_user_session_url}")
    end

    it "should be sent to the partner main email with the correct subject line" do
      expect(subject.to).to eq([partner.email])
      expect(subject.from).to eq(['no-reply@humanessentials.app'])
      expect(subject.subject).to eq("[Action Required] Please Update Your Agency Information")
    end
  end

  describe "#application_approved" do
    subject { PartnerMailer.application_approved(partner: partner) }
    let(:partner) { create(:partner) }

    it "should be sent to the partner main email with the correct subject line" do
      expect(subject.to).to eq([partner.email])
      expect(subject.from).to eq(['no-reply@humanessentials.app'])
      expect(subject.subject).to eq("Application Approved")
    end

    it "renders the body with text that indicates the result and a link to their dashboard" do
      expect(subject.body.encoded).to include("Hi #{partner.name}")
      expect(subject.body.encoded).to include("#{partner.organization.name} has approved your application.")
      expect(subject.body.encoded).to include("/partners/dashboard")
    end
  end
end
