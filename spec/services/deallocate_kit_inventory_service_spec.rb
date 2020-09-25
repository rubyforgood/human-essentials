RSpec.describe DeallocateKitInventoryService, type: :service do
  let(:organization) { create :organization }
  let(:item1) { create(:item, name: "Item11", organization: organization, on_hand_minimum_quantity: 5) }
  let(:item2) { create(:item, name: "Item 2", organization: organization, on_hand_minimum_quantity: 1) }

  let(:storage_location) { create(:storage_location, organization: organization) }
  let(:item_inventory1) { create(:inventory_item, storage_location: storage_location, quantity: item1.on_hand_minimum_quantity, item: item1) }
  let(:item_inventory2) { create(:inventory_item, storage_location: storage_location, quantity: item2.on_hand_minimum_quantity, item: item2) }

  describe "#error" do
    let(:kit) { Kit.create(params) }

    context "when kit couldn't be deallocated" do
      let(:wrong_item_id) { item1.id * 1000 }
      let(:params) do
        {
          organization_id: organization.id,
          line_items_attributes: {
            "0": { item_id: wrong_item_id, quantity: 5 }
          }
        }
      end

      it "returns error" do
        service = DeallocateKitInventoryService.new(kit, storage_location).deallocate
        expect(service.error).to include("Couldn't find Item with")
      end
    end

    context "when the Store location organization does't match" do
      let(:wrong_storage) { create(:storage_location) }
      let(:params) do
        {
          organization_id: organization.id,
          line_items_attributes: {
            "0": { item_id: item1.id, quantity: 5 }
          }
        }
      end

      it "returns error" do
        service = DeallocateKitInventoryService.new(kit, wrong_storage).deallocate
        expect(service.error).to include("Storage location kit doesn't match")
      end
    end
  end

  describe "#deallocate" do
    let(:kit) { Kit.create(params) }

    context "when inventory items are available" do
      let(:quantity_of_items1) { 3 }
      let(:quantity_of_items2) { 3 }
      let(:params) do
        {
          organization_id: organization.id,
          line_items_attributes: {
            "0": { item_id: item1.id, quantity: quantity_of_items1 },
            "1": { item_id: item2.id, quantity: quantity_of_items2 }
          }
        }
      end

      it "deallocates items" do
        before_deallocate1 = item_inventory1.quantity
        before_deallocate2 = item_inventory2.quantity

        service = DeallocateKitInventoryService.new(kit, storage_location).deallocate

        expect(service.error).to be_nil
        expect(item_inventory1.reload.quantity).to eq(before_deallocate1 + quantity_of_items1)
        expect(item_inventory2.reload.quantity).to eq(before_deallocate2 + quantity_of_items2)
      end
    end

    context "when inventory item doesn't exist" do
      let(:wrong_item_id) { item1.id * 1000 }
      let(:params) do
        {
          organization_id: organization.id,
          line_items_attributes: {
            "0": { item_id: item1.id, quantity: 1 },
            "1": { item_id: item2.id, quantity: 1 }
          }
        }
      end

      before do
        item2.destroy!
      end

      it "returns error" do
        before_try_deallocate1 = item_inventory1.quantity
        before_try_deallocate2 = item_inventory2.quantity

        service = DeallocateKitInventoryService.new(kit, storage_location).deallocate

        expect(service.error).to include("Couldn't find Item with")
        expect(item_inventory1.reload.quantity).to eq(before_try_deallocate1)
        expect(item_inventory2.reload.quantity).to eq(before_try_deallocate2)
      end
    end
  end
end
