# Spec for /app/queries/items_out_query.rb

RSpec.describe ItemsOutQuery do
  let(:organization) { create(:organization) }
  let!(:storage_location) { create(:storage_location, organization: organization) }
  subject { ItemsOutQuery.new(storage_location: storage_location, organization: organization).call }

  describe "items_out_query" do
    before do
      items = create_list(:item, 3, organization: organization)
      TestInventory.create_inventory(storage_location.organization, {
        storage_location.id => items.to_h { |i| [i.id, 10] }
      })
      other_storage_location = create(:storage_location, organization: organization)
      create(:transfer, :with_items, item_quantity: 8, item: items[0], to: other_storage_location, from: storage_location, organization: organization)
      create(:distribution, :with_items, item: items[1], item_quantity: 9, storage_location: storage_location, organization: organization)
      create(:adjustment, :with_items, item: items[2], item_quantity: -10, storage_location: storage_location, organization: organization)
    end

    it "returns a collection with the fields name, item_id, quantity" do
      expect(subject.first).to be_respond_to(:name)
      expect(subject.first).to be_respond_to(:quantity)
      expect(subject.first).to be_respond_to(:item_id)
    end

    it "includes distributions, adjustments, transfers among sources" do
      expect(subject.to_a.size).to eq(3)
    end
  end
end
