# Spec for /app/queries/items_in_total_query.rb

RSpec.describe ItemsInTotalQuery do
  let!(:storage_location) { create(:storage_location, organization: @organization) }
  let!(:other_storage_location) { create(:storage_location, :with_items, item: create(:item), item_quantity: 10, organization: @organization) }
  let!(:shared_item) { create(:item) }
  subject { ItemsInTotalQuery.new(storage_location: storage_location, organization: @organization).call }

  describe "items_in_total_query" do
    before do
      create(:donation, :with_items, item: create(:item), item_quantity: 10, storage_location: storage_location)
      create(:purchase, :with_items, item: create(:item), item_quantity: 10, storage_location: storage_location)
      create(:adjustment, :with_items, item: create(:item), item_quantity: 10, storage_location: storage_location)
      create(:transfer, :with_items, item_quantity: 10, item: other_storage_location.inventory_items.first.item, from: other_storage_location, to: storage_location)
      kit = create(:kit, :with_item, organization: @organization)
      create(:kit_allocation, :with_items, kit_allocation_type: "inventory_in", kit_id: kit.id, storage_location: storage_location, organization_id: @organization.id)
    end

    it "returns a sum total of all in-flows" do
      expect(subject).to eq(41)
    end

    it "counts shared items together" do
      create(:donation, :with_items, item: shared_item, item_quantity: 50, storage_location: storage_location)
      create(:purchase, :with_items, item: shared_item, item_quantity: 100, storage_location: storage_location)
      create(:adjustment, :with_items, item: shared_item, item_quantity: 50, storage_location: storage_location)
      create(:donation, :with_items, item: shared_item, item_quantity: 100, storage_location: storage_location)
      create(:purchase, :with_items, item: shared_item, item_quantity: 50, storage_location: storage_location)
      create(:adjustment, :with_items, item: shared_item, item_quantity: 100, storage_location: storage_location)
      expect(subject).to eq(491)
    end

    it "does not count negative adjustments towards in-flow" do
      create(:donation, :with_items, item: shared_item, item_quantity: 10, storage_location: storage_location)
      create(:adjustment, :with_items, item: shared_item, item_quantity: -10, storage_location: storage_location)
      expect(subject).to eq(51)
    end

    it "does not count transfers going in the negative direction" do
      create(:donation, :with_items, item: shared_item, item_quantity: 10, storage_location: storage_location)
      create(:transfer, :with_items, item_quantity: 10, item: shared_item, from: storage_location, to: other_storage_location)
      expect(subject).to eq(51)
    end

    it "does not count donations, purchases, adjustments to other storage locations" do
      create(:donation, :with_items, item: create(:item), item_quantity: 100, storage_location: other_storage_location)
      create(:purchase, :with_items, item: create(:item), item_quantity: 10, storage_location: other_storage_location)
      create(:adjustment, :with_items, item: create(:item), item_quantity: 10, storage_location: other_storage_location)
      expect(subject).to eq(41)
    end
  end
end
