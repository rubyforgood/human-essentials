RSpec.describe UpdateDiaperPartnerJob, job: true do
  describe ".perform_async" do
    it "updates partner status to Pending" do
      Sidekiq::Testing.inline! do
        partner = create(:partner)

        UpdateDiaperPartnerJob.perform_async(partner.id)

        expect(partner.reload.status).to eq("Pending")
      end
    end

    it "posts via DiaperPartnerClient" do
      Sidekiq::Testing.inline! do
        partner = create(:partner)
        allow(Flipper).to receive(:enabled?) { true }

        expect(DiaperPartnerClient).to receive(:post)

        UpdateDiaperPartnerJob.perform_async(partner.id)
      end
    end

    describe "Responses >" do
      before do
        allow(Flipper).to receive(:enabled?) { true }
        @partner = create(:partner)
      end
      context "with a successful POST response" do
        before do
          response = double("Response", value: Net::HTTPSuccess)
          allow(DiaperPartnerClient).to receive(:post).and_return(response)
        end

        it "sets the partner status to pending" do
          expect do
            UpdateDiaperPartnerJob.perform_async(@partner.id)
            @partner.reload
          end.to change { @partner.status }.to("Pending")
        end
      end

      context "with a unsuccessful POST response" do
        before do
          response = double("Response", value: nil)
          allow(DiaperPartnerClient).to receive(:post).and_return(response)
        end

        it "sets the partner status to error" do
          expect do
            UpdateDiaperPartnerJob.perform_async(@partner.id)
            @partner.reload
          end.to change { @partner.status }.to("Error")
        end
      end
    end
  end
end
