RSpec.describe UpdateDiaperPartnerJob, job: true do
  describe "Responses >" do
    before do
      @partner = create(:partner)
    end
    context "with a successful POST response" do
      before do
        response = double("Response", value: Net::HTTPSuccess)
        allow(DiaperPartnerClient).to receive(:post).and_return(response)
      end

      it "sets the partner status to pending" do
        with_features email_active: true do
          Sidekiq::Testing.inline! do
            expect do
              UpdateDiaperPartnerJob.perform_async(@partner.id)
              @partner.reload
            end.to change { @partner.status }.to("Pending")
          end
        end
      end
    end

    context "with a unsuccessful POST response" do
      before do
        response = double("Response", value: nil)
        allow(DiaperPartnerClient).to receive(:post).and_return(response)
      end

      it "sets the partner status to error" do
        Sidekiq::Testing.inline! do
          expect do
            UpdateDiaperPartnerJob.perform_async(@partner.id)
            @partner.reload
          end.to change { @partner.status }.to("Error")
        end
      end
    end
  end
end
