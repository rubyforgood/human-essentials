# == Schema Information
#
# Table name: adjustments
#
#  id                  :integer          not null, primary key
#  comment             :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  organization_id     :integer
#  storage_location_id :integer
#  user_id             :bigint
#

RSpec.describe Adjustment, type: :model do
  it_behaves_like "itemizable"
  # This mixes feature specs with model specs... idealy we do not want to do this
  # it_behaves_like "pagination"
  #
  let(:organization) { create(:organization) }

  context "Validations >" do
    it "must belong to an organization" do
      expect(build(:adjustment, storage_location: create(:storage_location), organization_id: nil)).not_to be_valid
    end

    it "allows you to add inventory that doesn't yet exist in the storage location" do
      expect(build(:adjustment, :with_items, item_quantity: 10, item: create(:item), storage_location: create(:storage_location))).to be_valid
    end

    it "allows you to remove all the inventory that exists in the storage location" do
      storage_location1 = create(:storage_location)
      item1 = create(:item)
      TestInventory.create_inventory(storage_location1.organization, {
        storage_location1.id => {
          item1.id => 10
        }
      })
      expect(build(:adjustment, :with_items, item_quantity: -10, item: item1, storage_location: storage_location1)).to be_valid
    end
  end

  context "Scopes >" do
    let(:user) { create(:user, organization: organization) }
    let(:organization_admin) { create(:organization_admin, organization: organization) }

    it "`at_location` can filter out adjustments to a specific location" do
      adj1 = create(:adjustment)
      create(:adjustment)
      expect(Adjustment.at_location(adj1.storage_location_id).size).to eq(1)
    end

    it "`by_user` can filter out adjustments to a specific user" do
      adj1 = create(:adjustment, user_id: user.id)
      create(:adjustment, user_id: organization_admin.id)
      expect(Adjustment.by_user(adj1.user_id).size).to eq(1)
    end
  end

  context "Methods >" do
    it "`self.storage_locations_adjusted_for` returns only storage_locations that are used in adjustments for one org" do
      storage_location1 = create(:storage_location, organization: organization)
      storage_location2 = create(:storage_location, organization: organization)
      create(:storage_location, organization: organization)
      storage_location4 = create(:storage_location, organization: create(:organization))
      create(:adjustment, storage_location: storage_location1, organization: organization)
      create(:adjustment, storage_location: storage_location2, organization: organization)
      create(:adjustment, storage_location: storage_location4, organization: storage_location4.organization)
      expect(Adjustment.storage_locations_adjusted_for(organization).to_a).to match_array([storage_location1, storage_location2])
    end

    describe "split_difference" do
      it "returns two adjustment objects" do
        item = create(:item)
        storage_location = create(:storage_location, :with_items, item: item, item_quantity: 10)
        TestInventory.create_inventory(organization, {
          storage_location.id => {
            create(:item).id => 10
          }
        })
        adjustment = create(:adjustment,
                            storage_location: storage_location,
                            line_items_attributes: [
                              { item_id: storage_location.items.first.id, quantity: 10 },
                              { item_id: storage_location.items.last.id, quantity: -5 }
                            ])
        pos, neg = adjustment.split_difference
        expect(pos.line_items.size).to eq(1)
        expect(neg.line_items.size).to eq(1)
        expect(pos.line_items.first.quantity).to eq(10)
        expect(neg.line_items.first.quantity).to eq(5)
      end

      it "gracefully handles adjustments with only positive" do
        item = create(:item)
        storage_location = create(:storage_location, :with_items, item: item, item_quantity: 10)
        TestInventory.create_inventory(storage_location.organization,
                                       storage_location.id => { create(:item).id => 10 })
        adjustment = create(:adjustment,
                            storage_location: storage_location,
                            line_items_attributes: [
                              { item_id: storage_location.items.first.id, quantity: 10 },
                              { item_id: storage_location.items.last.id, quantity: 5 }
                            ])
        pos, neg = adjustment.split_difference
        expect(pos.line_items.size).to eq(2)
        expect(pos.line_items.first.quantity).to eq(10)
        expect(pos.line_items.last.quantity).to eq(5)
        expect(neg.line_items).to be_empty
      end
      it "gracefully handles adjustments with only negative" do
        item = create(:item)
        storage_location = create(:storage_location, :with_items, item: item, item_quantity: 10)
        TestInventory.create_inventory(storage_location.organization,
                                       storage_location.id => { create(:item).id => 10 })
        adjustment = create(:adjustment,
                            storage_location: storage_location,
                            line_items_attributes: [
                              { item_id: storage_location.items.first.id, quantity: -10 },
                              { item_id: storage_location.items.last.id, quantity: -5 }
                            ])
        pos, neg = adjustment.split_difference
        expect(neg.line_items.size).to eq(2)
        expect(neg.line_items.first.quantity).to eq(10)
        expect(neg.line_items.last.quantity).to eq(5)
        expect(pos.line_items).to be_empty
      end
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

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
