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

######### NEW CODE FROM HERE DOWN
#test to see that status WAS updated given post was successfull
    it "checks status given successfull POST" do
        before do
            @response&.value = Net::HTTPSuccess
        end
        expect(@partner.status).to eq("Pending")
    end

#2 tests to see that status WAS NOT updated given post was UNsuccessfull
    it "checks status given unsuccessfull POST(Client Error)" do
        before do
            @response&.value = Net::HTTPClientError
        end
        expect(@partner.status).to eq("Error")
    end

    it "checks status given unsuccessfull POST(Server Error)" do
        before do
            @response&.value = Net::HTTPServerError
        end
        expect(@partner.status).to eq("Error")
    end




#?test to make sure no info sent to Partner app breaks Partner app?

  end
end





## 2 tests that mock DiaperPartnerClient and responds with 1)successfull and 2)unsuccessfull
## test the response of the entire job(should be @partner status)

##factory that creates fake partner which would allow complete controll over both inputs which would make the test more reliable and repeatable
