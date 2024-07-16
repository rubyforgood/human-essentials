# == Schema Information
#
# Table name: audits
#
#  id                  :bigint           not null, primary key
#  status              :integer          default("in_progress"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  adjustment_id       :bigint
#  organization_id     :bigint
#  storage_location_id :bigint
#  user_id             :bigint
#

RSpec.describe Audit, type: :model do
  let(:organization) { create(:organization) }

  it_behaves_like "itemizable"

  context "Validations >" do
    let(:user) { create(:user, organization: organization) }
    let(:organization_admin) { create(:organization_admin, organization: organization) }

    it "must belong to an organization" do
      expect(build(:audit, storage_location: create(:storage_location), organization_id: nil)).not_to be_valid
      expect(build(:audit, organization: organization)).to be_valid
    end

    it "must belong to an organization admin of its organization" do
      expect(build(:audit, storage_location: create(:storage_location, organization: organization), user: user, organization: organization)).not_to be_valid
      expect(build(:audit, storage_location: create(:storage_location, organization: organization), user: organization_admin,  organization: organization)).to be_valid
    end

    it "can not have line items that has quantity as negative integer" do
      item = create(:item)
      storage_location = create(:storage_location, :with_items, item: item, item_quantity: 10)
      audit = build(:audit,
                    storage_location: storage_location,
                    line_items_attributes: [
                      { item_id: storage_location.items.first.id, quantity: -1 }
                    ])

      expect(audit.save).to be_falsey
    end

    it "can have line items that has quantity as zero" do
      item = create(:item)
      storage_location = create(:storage_location, :with_items, item: item, item_quantity: 10)
      audit = build(:audit,
                    storage_location: storage_location,
                    line_items_attributes: [
                      { item_id: storage_location.items.first.id, quantity: 0 }
                    ])

      expect(audit.save).to be_truthy
    end

    it "can not have line items that has quantity as a string that cannot be reduced to an integer" do
      item = create(:item)
      storage_location = create(:storage_location, :with_items, item: item, item_quantity: 10)
      audit = build(:audit,
                    storage_location: storage_location,
                    line_items_attributes: [
                      { item_id: storage_location.items.first.id, quantity: "three" }
                    ])

      expect(audit.save).to be_falsey
    end

    it 'cannot have duplicate line items' do
      item = create(:item, name: "Dupe Item")
      storage_location = create(:storage_location, :with_items, item: item, item_quantity: 10)
      audit = build(:audit,
                    storage_location: storage_location,
                    line_items_attributes: [
                      { item_id: item.id, quantity: 3 },
                      { item_id: item.id, quantity: 5 }
                    ])

      expect(audit.save).to be_falsey
      expect(audit.errors.full_messages).to eq(["You have entered at least one duplicate item: Dupe Item"])
    end

    it "can have line items that has quantity as a positive integer" do
      item = create(:item)
      storage_location = create(:storage_location, :with_items, item: item, item_quantity: 10)
      audit = build(:audit,
                    storage_location: storage_location,
                    line_items_attributes: [
                      { item_id: storage_location.items.first.id, quantity: 10 }
                    ])

      expect(audit.save).to be_truthy
    end
  end

  context "Scopes >" do
    it "`at_location` can filter out audits to a specific location" do
      audit1 = create(:audit)
      create(:audit)
      expect(Audit.at_location(audit1.storage_location_id).size).to eq(1)
    end
  end

  context "Methods >" do
    it "`self.storage_locations_audited_for` returns only storage_locations that are used for one org" do
      storage_location1 = create(:storage_location, organization: organization)
      storage_location2 = create(:storage_location, organization: organization)
      create(:storage_location, organization: organization)
      storage_location4 = create(:storage_location, organization: create(:organization))
      create(:audit, storage_location: storage_location1, organization: organization)
      create(:audit, storage_location: storage_location2, organization: organization)
      create(:audit, storage_location: storage_location4, organization: storage_location4.organization)
      expect(Audit.storage_locations_audited_for(organization).to_a).to match_array([storage_location1, storage_location2])
    end

    it "`self.finalized_since?` returns true iff some finalized audit occurred after itemizable created_at that shares item for location(s)" do
      storage_location1 = create(:storage_location, :with_items, item_quantity: 10, organization: organization)
      storage_location2 = create(:storage_location, :with_items, item_quantity: 10, organization: organization)
      storage_location3 = create(:storage_location, :with_items, item_quantity: 10, organization: organization)
      storage_location4 = create(:storage_location, organization: organization)
      storage_location5 = create(:storage_location, :with_items,  item_quantity: 10, organization: organization)

      create(:audit, storage_location: storage_location2, status: "finalized", line_items_attributes: [{item_id: storage_location2.items.first.id, quantity: 10}])

      xfer1 = create(:transfer, :with_items, item_quantity: 5, item: storage_location1.items.first, from: storage_location1, to: storage_location2, organization: organization)
      xfer2 = create(:transfer, :with_items, item_quantity: 5, item: storage_location1.items.first, from: storage_location1, to: storage_location3, organization: organization)
      xfer3 = create(:transfer, :with_items, item_quantity: 10, item: storage_location2.items.first, from: storage_location2, to: storage_location3, organization: organization)

      create(:audit, storage_location: storage_location1, status: "finalized", line_items_attributes: [{item_id: storage_location1.items.first.id, quantity: 5}])
      create(:audit, storage_location: storage_location3, status: "finalized", line_items_attributes: [{item_id: storage_location3.items.first.id, quantity: 10}])
      create(:audit, storage_location: storage_location5, status: "confirmed", line_items_attributes: [{item_id: storage_location5.items.first.id, quantity: 10}])

      expect(Audit.finalized_since?(xfer1, storage_location1.id)).to be true # match items and location and occurs after
      expect(Audit.finalized_since?(xfer1, storage_location1.id, storage_location2.id)).to be true # handles multiple locations
      expect(Audit.finalized_since?(xfer3, storage_location2)).to be false # match items and location but occurs before
      expect(Audit.finalized_since?(xfer2, storage_location3.id)).to be false # match location and occurs after but different items
      expect(Audit.finalized_since?(xfer3, storage_location4)).to be false # no audits at location
      expect(Audit.finalized_since?(xfer3, storage_location5)).to be false # since status isn't finalized
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
