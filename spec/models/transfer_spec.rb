# == Schema Information
#
# Table name: transfers
#
#  id              :integer          not null, primary key
#  comment         :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  from_id         :integer
#  organization_id :integer
#  to_id           :integer
#

RSpec.describe Transfer, type: :model do
  let(:organization) { create(:organization) }

  it_behaves_like "itemizable"

  context "Validations >" do
    it { should belong_to(:organization).inverse_of(:transfers) }
    it { should belong_to(:from).class_name("StorageLocation").inverse_of(:transfers_from) }
    it { should belong_to(:to).class_name("StorageLocation").inverse_of(:transfers_to) }

    it "must have different storage locations" do
      transfer = build(:transfer)
      transfer.to = transfer.from
      expect(transfer).not_to be_valid
    end

    it "must only use storage locations that belong to the organization (no hacks!)" do
      transfer = build(:transfer)
      other_org = create(:organization)
      other_storage = create(:storage_location, organization: other_org)
      transfer.from = other_storage
      expect(transfer).not_to be_valid
    end

    it "requires that each line item exists in the inventory" do
      transfer = build(:transfer, :with_items)
      item = create(:item)
      transfer.line_items.first.item = item
      expect(transfer).not_to be_valid
    end

    it "requires that the line items must have sufficient quantity in the inventory" do
      item = create(:item)
      transfer = build(:transfer, :with_items, item: item, item_quantity: 10)

      TestInventory.clear_inventory(transfer.from)
      TestInventory.create_inventory(transfer.organization, {
        transfer.from.id => {
          item.id => 5
        }
      })
      expect(transfer).not_to be_valid
    end
  end

  context "Scopes >" do
    it "`from_location` can filter out transfers from a specific location" do
      xfer1 = create(:transfer, organization: organization)
      create(:transfer, organization: organization)
      expect(Transfer.from_location(xfer1.from_id).size).to eq(1)
    end
    it "`to_location` can filter out transfers to a specific location" do
      xfer1 = create(:transfer, organization: organization)
      create(:transfer, organization: organization)
      expect(Transfer.to_location(xfer1.to_id).size).to eq(1)
    end
  end

  context "Methods >" do
    it "`self.storage_locations_transferred_to` and `..._from` constrains appropriately" do
      storage_location1 = create(:storage_location, name: "loc1", organization: organization)
      storage_location2 = create(:storage_location, name: "loc2", organization: organization)
      storage_location3 = create(:storage_location, name: "loc3", organization: organization)
      storage_location4 = create(:storage_location, name: "loc4", organization: create(:organization))
      storage_location5 = create(:storage_location, name: "loc5", organization: storage_location4.organization)
      create(:transfer, from: storage_location3, to: storage_location1, organization: organization)
      create(:transfer, from: storage_location3, to: storage_location2, organization: organization)
      create(:transfer, from: storage_location5, to: storage_location4, organization: storage_location4.organization)
      expect(Transfer.storage_locations_transferred_to_in(organization).to_a).to match_array([storage_location1, storage_location2])
      expect(Transfer.storage_locations_transferred_from_in(organization).to_a).to match_array([storage_location3])
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
