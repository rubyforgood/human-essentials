# == Schema Information
#
# Table name: partner_served_areas
#
#  id                 :bigint           not null, primary key
#  client_share       :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  county_id          :bigint           not null
#  partner_profile_id :bigint           not null
#

RSpec.describe Partners::ServedArea, type: :model do
  describe "validations" do
    let(:served_area_nil_client_share) { build(:partners_served_area, partner_profile: create(:partner_profile), county: create(:county), client_share: nil) }
    it { should belong_to(:partner_profile) }
    it { should belong_to(:county) }

    it "displays a user friendly error message for nil client shares" do
      expect(served_area_nil_client_share).not_to be_valid
      expect(served_area_nil_client_share.errors.messages[:client_share]).to match_array(["Client share must be between 1 and 100 inclusive", "is not a number"])
    end

    it "must only allow integer client shares" do
      expect(build(:partners_served_area, partner_profile: create(:partner_profile), county: create(:county), client_share: 50)).to be_valid
      expect(build(:partners_served_area, partner_profile: create(:partner_profile), county: create(:county), client_share: 50.5)).not_to be_valid
    end

    it "must only allow valid client share values" do
      expect(build(:partners_served_area, partner_profile: create(:partner_profile), county: create(:county), client_share: 0)).not_to be_valid
      expect(build(:partners_served_area, partner_profile: create(:partner_profile), county: create(:county), client_share: 101)).not_to be_valid
      expect(build(:partners_served_area, partner_profile: create(:partner_profile), county: create(:county), client_share: 1)).to be_valid
      expect(build(:partners_served_area, partner_profile: create(:partner_profile), county: create(:county), client_share: 100)).to be_valid
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
