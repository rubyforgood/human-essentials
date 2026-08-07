RSpec.describe RequestMailer, type: :mailer do
  describe "#request_cancel_partner_notification" do
    subject { described_class.request_cancel_partner_notification(request_id: request.id) }

    let(:partner) { create(:partner, email: "partner@example.com") }

    context "when the request was sent by a partner user" do
      let(:partner_user) { create(:partner_user, email: "requester@example.com", partner: partner) }
      let(:request) { create(:request, partner: partner, partner_user: partner_user) }

      it "renders the body with correct text with partner information" do
        html = html_body(subject)
        expect(html).to include("Hello there, <strong>#{request.partner.name}</strong>")
        expect(html).to include("One of your essentials requests (##{request.id}) have been canceled.")
        text = text_body(subject)
        expect(text).to include("Hello there, #{request.partner.name}")
        expect(text).to include("One of your essentials requests (##{request.id}) have been canceled.")
      end

      it "is sent to both the partner and the request sender with the correct subject line" do
        expect(subject.to).to match_array(["partner@example.com", "requester@example.com"])
        expect(subject.from).to eq(['no-reply@humanessentials.app'])
        expect(subject.subject).to eq("Your essentials request (##{request.id}) has been canceled.")
      end
    end

    context "when the request has no partner user" do
      let(:request) { create(:request, partner: partner, partner_user: nil) }

      it "is sent only to the partner main email" do
        expect(subject.to).to eq(["partner@example.com"])
      end
    end
  end
end
