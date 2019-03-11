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
    it "checks status was updated given successfull POST" do
        expect(responseCode).to eq(NET::HTTPSuccess)
    end


#expect 2xx response code or NET::HTTPSuccess
#test to see that status WAS updated given post was successfull




#test to see that status WAS NOT updated given post was UNsuccessfull

#?test to make sure no info sent to Partner app breaks Partner app?



  end
end
