# Spec for /app/queries/items_in_query.rb

RSpec.describe ItemsInQuery do
  let!(:storage_location) { create(:storage_location, organization: @organization) }
  let!(:other_storage_location) { create(:storage_location, :with_items, item: create(:item), item_quantity: 10, organization: @organization) }
  subject { ItemsInQuery.new(storage_location: storage_location, organization: @organization).call }

  describe "items_in" do
    before do
      create_list(:donation, 2, :with_items, item: create(:item), item_quantity: 5, storage_location: storage_location)
      create_list(:purchase, 2, :with_items, item: create(:item), item_quantity: 5, storage_location: storage_location)
      create_list(:adjustment, 2, :with_items, item: create(:item), item_quantity: 5, storage_location: storage_location)
      create_list(:transfer, 2, :with_items, item_quantity: 5, item: other_storage_location.inventory_items.first.item, from: other_storage_location, to: storage_location)
      kit = create(:kit, :with_item, organization: @organization)
      create(:kit_allocation, :with_items, kit_allocation_type: "inventory_in", kit_id: kit.id, storage_location: storage_location, organization_id: @organization.id)
    end

    it "returns a collection with the fields name, item_id, quantity" do
      expect(subject.first).to be_respond_to(:name)
      expect(subject.first).to be_respond_to(:quantity)
      expect(subject.first).to be_respond_to(:item_id)
    end

    it "includes donations, purchases, adjustments, transfers, kit_allocations among sources" do
      expect(subject.to_a.size).to eq(5)
    end

    it "does not count negative adjustments towards in-flow" do
      shared_item = create(:item)
      create(:donation, :with_items, item: shared_item, item_quantity: 10, storage_location: storage_location)
      create(:adjustment, :with_items, item: shared_item, item_quantity: -10, storage_location: storage_location)
      expect(subject.to_a.size).to eq(6)
    end

    it "does not count transfers going in the negative direction" do
      shared_item = create(:item)
      create(:donation, :with_items, item: shared_item, item_quantity: 10, storage_location: storage_location)
      create(:transfer, :with_items, item_quantity: 10, item: shared_item, from: storage_location, to: other_storage_location)
      expect(subject.to_a.size).to eq(6)
    end
  end
end
