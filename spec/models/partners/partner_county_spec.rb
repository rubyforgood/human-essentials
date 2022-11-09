require "rails_helper"

RSpec.describe PartnerCounty, type: :model do
  before do
    county = County.create(name: "A County", region: "A region")
    partner = FactoryBot.create(:partner)
    pc = PartnerCounty.create(partner: partner, county: county)
  end

  describe "associations" do
    it { should belong_to(:partner) }
    it { should belong_to(:county) }
  end
  describe "client share values" do
    let(:county) { FactoryBot.create(:county) }
    let(:partner) { FactoryBot.create(:partner) }

    it 'should not be valid with negative client share' do
      expect(build(:partner_county, partner: partner, county: county, client_share: -1)).not_to be_valid
    end

    it 'should not be valid with client share over 100' do
      expect(build(:partner_county, partner: partner, county: county, client_share: 101)).not_to be_valid
    end

    it 'should be valid with client share between 0 and 100 inclusive' do
      expect(build(:partner_county, partner: partner, county: county, client_share: 0)).to be_valid
      expect(build(:partner_county, partner: partner, county: county, client_share: 100)).to be_valid
    end
  end
end