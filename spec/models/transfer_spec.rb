# == Schema Information
#
# Table name: transfers
#
#  id              :integer          not null, primary key
#  from_id         :integer
#  to_id           :integer
#  comment         :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#

RSpec.describe Transfer, type: :model do
  it_behaves_like "itemizable"
  # 2 Specs are failing here because

  context "Validations >" do
    it "must belong to an organization" do
      expect(build(:transfer, organization_id: nil)).not_to be_valid
    end
  end

  context "Scopes >" do
    it "`from_location` can filter out transfers from a specific location" do
      xfer1 = create(:transfer, organization: @organization)
      create(:transfer, organization: @organization)
      expect(Transfer.from_location(xfer1.from_id).size).to eq(1)
    end
    it "`to_location` can filter out transfers to a specific location" do
      xfer1 = create(:transfer, organization: @organization)
      create(:transfer, organization: @organization)
      expect(Transfer.to_location(xfer1.to_id).size).to eq(1)
    end
  end

  context "Methods >" do
    it "`self.storage_locations_transferred_to` and `..._from` constrains appropriately" do
      storage_location1 = create(:storage_location, name: "loc1", organization: @organization)
      storage_location2 = create(:storage_location, name: "loc2", organization: @organization)
      storage_location3 = create(:storage_location, name: "loc3", organization: @organization)
      storage_location4 = create(:storage_location, name: "loc4", organization: create(:organization))
      storage_location5 = create(:storage_location, name: "loc5", organization: storage_location4.organization)
      create(:transfer, from: storage_location3, to: storage_location1, organization: @organization)
      create(:transfer, from: storage_location3, to: storage_location2, organization: @organization)
      create(:transfer, from: storage_location5, to: storage_location4, organization: storage_location4.organization)
      expect(Transfer.storage_locations_transferred_to_in(@organization).to_a).to match_array([storage_location1, storage_location2])
      expect(Transfer.storage_locations_transferred_from_in(@organization).to_a).to match_array([storage_location3])
    end
  end
end
