RSpec.describe PartnerMailer, type: :mailer do
  describe "#recertification_request" do
    subject { PartnerMailer.recertification_request(partner: partner) }
    let(:partner) { create(:partner) }
    let(:fake_partner_base_url) { Faker::Internet.domain_name }
    before do
      allow(ENV).to receive(:[]).with("PARTNER_BASE_URL").and_return(fake_partner_base_url)
    end

    it "renders the body with text that indicates to recertify and link to where" do
      expect(subject.body.encoded).to include("Hi #{partner.name}")
      expect(subject.body.encoded).to include("It's time to update your agency information!")
      expect(subject.body.encoded).to include("Please log in to your account at #{fake_partner_base_url}")
    end

    it "should be sent to the partner main email with the correct subject line" do
      expect(subject.to).to eq([partner.email])
      expect(subject.from).to eq(['info@diaper.app'])
      expect(subject.subject).to eq("[Action Required] Please Update Your Agency Information")
    end
  end
end

