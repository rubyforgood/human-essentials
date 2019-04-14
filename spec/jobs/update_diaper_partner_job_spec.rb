RSpec.describe UpdateDiaperPartnerJob, job: true do
  describe "Responses >" do
    context "with a successful POST response" do
      before do
        @partner = create(:partner)
        puts "XXXXX - #{@partner.inspect}"
        response = double("Response", value: Net::HTTPSuccess)
        allow(DiaperPartnerClient).to receive(:post).and_return(response)
      end

      it "checks the partner status is default set to pending" do
        with_features email_active: true do
          Sidekiq::Testing.inline! do
            expect do
              puts "YYYYY before perform async - #{@partner.inspect}"
              UpdateDiaperPartnerJob.perform_async(@partner.id)
              puts "YYYYY after perform async - #{@partner.inspect}"
              @partner.reload
              puts "YYYYY after reload - #{@partner.inspect}"
            end
            expect(@partner.status).to eq("pending")
          end
        end
      end
    end

    context "with a unsuccessful POST response" do
      before do
        @partner = create(:partner)
        puts "ZZZZ partner - #{@partner.inspect}"
        response = double("Response", value: nil)
        allow(DiaperPartnerClient).to receive(:post).and_return(response)
      end

      it "sets the partner status to error" do
        with_features email_active: true do
          Sidekiq::Testing.inline! do
            expect do
              puts "ZZZZ before perform_async - #{@partner.inspect}"
              UpdateDiaperPartnerJob.perform_async(@partner.id)
              puts "ZZZZ after perform_async - #{@partner.inspect}"
              @partner.reload
              puts "ZZZZ after reload - #{@partner.inspect}"
            end.to change { @partner.status }.to("error")
          end
        end
      end
      it "posts via DiaperPartnerClient" do
        with_features email_active: true do
          Sidekiq::Testing.inline! do
            partner = create(:partner)
            allow(Flipper).to receive(:enabled?) { true }

            expect(DiaperPartnerClient).to receive(:post)

            UpdateDiaperPartnerJob.perform_async(partner.id)
          end
        end
      end
    end
  end
end
