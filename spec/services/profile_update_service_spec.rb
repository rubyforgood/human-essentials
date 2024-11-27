RSpec.describe ProfileUpdateService do
  describe "#update" do
    let(:partner) { create(:partner, name: "Partnerrific") }
    let(:partner_user) { partner.primary_user }
    let(:params) { {address2: "Washington, DC"} }

    it "updates the profile with the filtered and prepared params" do
      expect(partner.profile.address1).to be_nil

      result = described_class.update(partner.profile, params)
      expect(result).to eq(true)
      expect(partner.profile.address2).to eq("Washington, DC")
    end
  end
end
