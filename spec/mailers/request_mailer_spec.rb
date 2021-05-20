RSpec.describe RequestMailer, type: :mailer do
  describe "#request_cancel_partner_notification" do
    subject { described_class.request_cancel_partner_notification(request_id: request.id) }
    let(:request) { create(:request) }

    it "renders the body with correct text with partner information" do
      expect(subject.body.encoded).to include("Hello there, <strong>#{request.partner.name}</strong>")
      expect(subject.body.encoded).to include("One of your essentials requests (##{request.id}) have been canceled.")
    end

    it "should be sent to the partner main email with the correct subject line" do
      expect(subject.to).to eq([request.partner.email])
      expect(subject.from).to eq(['info@diaper.app'])
      expect(subject.subject).to eq("Your essentials request (##{request.id}) has been canceled.")
    end
  end
end

