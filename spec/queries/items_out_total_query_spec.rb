# Spec for /app/queries/items_out_total_query.rb

RSpec.describe ItemsOutTotalQuery do
  let!(:storage_location) { create(:storage_location, organization: @organization) }
  subject { ItemsOutTotalQuery.new(storage_location: storage_location, organization: @organization).call }

  describe "items_out_total_query" do
    before do
      items = create_list(:inventory_item, 3, storage_location: storage_location, quantity: 10).collect(&:item)
      other_storage_location = create(:storage_location, organization: @organization)
      create(:transfer, :with_items, item_quantity: 10, item: items[0], to: other_storage_location, from: storage_location)
      create(:distribution, :with_items, item: items[1], item_quantity: 10, storage_location: storage_location)
      create(:adjustment, :with_items, item: items[2], item_quantity: -10, storage_location: storage_location)
      kit = create(:kit, :with_item, organization: @organization)
      create(:kit_allocation, :with_items, kit_allocation_type: "inventory_out", kit_id: kit.id, storage_location: storage_location, organization_id: @organization.id)
    end

    it "returns a sum total of all out-flows" do
      expect(subject).to eq(31)
    end
  end
end
