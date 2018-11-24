RSpec.describe UpdateDiaperPartnerJob, job: true do
  describe ".perform_async" do
    it "updates partner status to Pending" do
      partner = create(:partner)

      UpdateDiaperPartnerJob.perform_async(partner.id)

      expect(partner.reload.status).to eq("Pending")
    end

    it "posts via DiaperPartnerClient" do
      partner = create(:partner)
      allow(Flipper).to receive(:enabled?) { true }

      expect(DiaperPartnerClient).to receive(:post)

      UpdateDiaperPartnerJob.perform_async(partner.id)
    end
  end
end
