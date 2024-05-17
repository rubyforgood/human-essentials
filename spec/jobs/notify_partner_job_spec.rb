RSpec.describe NotifyPartnerJob, job: true do
  describe "#perform" do
    let(:request) { create(:request) }
    let(:mailer) { double(:mailer) }

    before do
      allow(RequestsConfirmationMailer).to receive(:confirmation_email).and_return(mailer)
      allow(mailer).to receive(:deliver_later)
    end

    it "avoids exception when request doesn't exist" do
      expect do
        NotifyPartnerJob.perform_now(123)
      end.not_to raise_error
    end

    it "is expected to call RequestsConfirmationMailer" do
      NotifyPartnerJob.perform_now(request.id)
      expect(RequestsConfirmationMailer).to have_received(:confirmation_email).with(request)
      expect(mailer).to have_received(:deliver_later)
    end

    context "when the request's partner is deactivated" do
      let(:partner) { create(:partner, status: "deactivated") }
      let(:request) { create(:request, partner: partner) }

      it "does not send the confirmation email" do
        NotifyPartnerJob.perform_now(request.id)
        expect(RequestsConfirmationMailer).to_not have_received(:confirmation_email)
      end
    end
  end
end
