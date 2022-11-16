RSpec.describe DistributionUpdateService, type: :service do
  describe "call" do
    let(:county_1) { FactoryBot.create(:county) }
    let(:county_2) { FactoryBot.create(:county) }
    let(:partner) { FactoryBot.create(:partner) }
    let(:profile) { FactoryBot.create(:partners_partner, partner_id: partner.id) }

    it "passes if the total client share is 0" do
      new_attributes = {partner_counties_attributes: {}}
      expect(PartnerProfileUpdateService.new(profile, new_attributes).call).to be_truthy
    end

    it "fails with a 99% total client share" do
      new_attributes = {partner_counties_attributes: {"0": {county_id: county_1.__id__, client_share: 99}}}
      expect(PartnerProfileUpdateService.new(profile, new_attributes).call).to be_falsey
    end

    it "passes with a 100% total client share over 2 counties" do
      new_attributes = {partner_counties_attributes: {"0": {county_id: county_1.__id__, client_share: 99},
                                                      "1": {county_id: county_2.__id__, client_share: 1}}}
      expect(PartnerProfileUpdateService.new(profile, new_attributes).call).to be_truthy
    end

    it "fails with a 101% total client share over 2 counties" do
      new_attributes = {partner_counties_attributes: {"0": {county_id: county_1.__id__, client_share: 99},
                                                      "1": {county_id: county_2.__id__, client_share: 2}}}
      expect(PartnerProfileUpdateService.new(profile, new_attributes).call).to be_falsey
    end
  end
end
