RSpec.describe AllocateKitInventoryService, type: :service do
  let(:organization) { create :organization }
  let(:item) { create(:item, name: "Item", organization: organization, on_hand_minimum_quantity: 5) }
  let(:item_out_of_stock) { create(:item, name: "Item out of stock", organization: organization, on_hand_minimum_quantity: 0) }

  let(:storage_location) { create(:storage_location, organization: organization) }
  let(:item_inventory) { create(:inventory_item, storage_location: storage_location, quantity: item.on_hand_minimum_quantity, item: item) }
  let(:item_out_of_stock_inventory) { create(:inventory_item, storage_location: storage_location, quantity: item_out_of_stock.on_hand_minimum_quantity, item: item_out_of_stock) }

  describe "#error" do
    let(:kit) { Kit.create(params) }

    context "when inventory is not available" do
      let(:params) do
        {
          organization_id: organization.id,
          line_items_attributes: {
            "0": { item_id: item_out_of_stock.id, quantity: 5 }
          }
        }
      end

      it "returns error" do
        service = AllocateKitInventoryService.new(kit, storage_location).allocate
        expect(service.error).to include("Requested items exceed the available inventory")
      end
    end

    context "when the Store location organization does't match" do
      let(:wrong_storage) { create(:storage_location) }
      let(:params) do
        {
          organization_id: organization.id,
          line_items_attributes: {
            "0": { item_id: item_out_of_stock.id, quantity: 5 }
          }
        }
      end

      it "returns error" do
        service = AllocateKitInventoryService.new(kit, wrong_storage).allocate
        expect(service.error).to include("Storage location kit doesn't match")
      end
    end
  end

  describe "#allocate" do
    let(:kit) { Kit.create(params) }

    context "when inventory items are available" do
      let(:quantity_of_items) { 3 }
      let(:params) do
        {
          organization_id: organization.id,
          line_items_attributes: {
            "0": { item_id: item.id, quantity: quantity_of_items }
          }
        }
      end

      it "allocates items" do
        quantity_before_allocate = item_inventory.quantity
        service = AllocateKitInventoryService.new(kit, storage_location).allocate
        expect(item_inventory.reload.quantity).to eq(quantity_before_allocate - quantity_of_items)
        expect(service.error).to be_nil
      end
    end

    context "when more than one kit is requested" do
      let(:params) do
        {
          organization_id: organization.id,
          line_items_attributes: {
            "0": { item_id: item.id, quantity: quantity_of_items }
          }
        }
      end

      context "when one of the items are out of stock" do
        let(:quantity_of_items) { item_inventory.quantity }
        let(:quantity_of_kits) { 2 }

        it "returns error" do
          service = AllocateKitInventoryService.new(kit, storage_location, quantity_of_kits).allocate
          expect(service.error).to include("Requested items exceed the available inventory")
          expect(item_inventory.reload.quantity).to eq quantity_of_items
        end
      end

      context "when inventory can handle many items" do
        let(:quantity_of_items) { 2 }
        let(:quantity_of_kits) { 2 }

        it "allocates items" do
          before_allocate = item_inventory.quantity
          service = AllocateKitInventoryService.new(kit, storage_location, quantity_of_kits).allocate
          expect(service.error).to be_nil
          expect(item_inventory.reload.quantity).to eq(before_allocate - quantity_of_items * quantity_of_kits)
        end
      end
    end
  end
end
