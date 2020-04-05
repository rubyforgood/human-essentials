RSpec.describe UpdateDiaperPartnerJob, job: true do
  describe "Responses >" do
    context "with a successful POST response" do
      before do
        @partner = create(:partner)
        response = double("Response", value: Net::HTTPSuccess)
        allow(DiaperPartnerClient).to receive(:post).and_return(response)
      end

      it "checks the partner status is default set to pending" do
        with_features email_active: true do
          expect do
            UpdateDiaperPartnerJob.perform_now(@partner.id)
            @partner.reload
          end
          expect(@partner.status).to eq("uninvited")
        end
      end
    end

    context "with an unsuccessful POST response" do
      before do
        @partner = create(:partner)
        response = double("Response", value: nil)
        allow(DiaperPartnerClient).to receive(:post).and_return(response)
      end

      it "sets the partner status to error" do
        with_features email_active: true do
          expect do
            UpdateDiaperPartnerJob.perform_now(@partner.id)
            @partner.reload
          end.to change { @partner.status }.to("error")
        end
      end

      it "posts via DiaperPartnerClient" do
        with_features email_active: true do
          expect(DiaperPartnerClient).to receive(:post)
          UpdateDiaperPartnerJob.perform_now(@partner.id)
        end
      end
    end
  end
end
