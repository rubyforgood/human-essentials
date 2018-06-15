# == Schema Information
#
# Table name: adjustments
#
#  id                  :bigint(8)        not null, primary key
#  organization_id     :integer
#  storage_location_id :integer
#  comment             :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

RSpec.describe Adjustment, type: :model do
  it_behaves_like "itemizable"

  context "Validations >" do
    it "must belong to an organization" do
      expect(build(:adjustment, storage_location: create(:storage_location), organization_id: nil)).not_to be_valid
    end
  end

  context "Scopes >" do
    it "`at_location` can filter out adjustments to a specific location" do
      adj1 = create(:adjustment)
      create(:adjustment)
      expect(Adjustment.at_location(adj1.storage_location_id).size).to eq(1)
    end
  end

  context "Methods >" do
    it "`self.storage_locations_adjusted_for` returns only storage_locations that are used in adjustments for one org" do
      storage_location1 = create(:storage_location, organization: @organization)
      storage_location2 = create(:storage_location, organization: @organization)
      storage_location3 = create(:storage_location, organization: @organization)
      storage_location4 = create(:storage_location, organization: create(:organization))
      adj1 = create(:adjustment, storage_location: storage_location1, organization: @organization)
      adj2 = create(:adjustment, storage_location: storage_location2, organization: @organization)
      adj3 = create(:adjustment, storage_location: storage_location4, organization: storage_location4.organization)
      expect(Adjustment.storage_locations_adjusted_for(@organization).to_a).to match_array([storage_location1, storage_location2])
    end
  end

  describe "nested line item attributes" do
    it "accepts them" do
      item = create(:item)
      storage_location = create(:storage_location, :with_items, item: item, item_quantity: 10)

      new_adjustment = build(:adjustment,
                             storage_location: storage_location,
                             line_items_attributes: [
                               { item_id: storage_location.items.first.id, quantity: 10 }
                             ])

      expect(new_adjustment.save).to be_truthy
    end
  end
end
