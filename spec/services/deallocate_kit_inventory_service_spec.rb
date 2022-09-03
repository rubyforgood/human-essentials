RSpec.describe DeallocateKitInventoryService, type: :service do
  let(:organization) { create :organization }
  let(:item1) { create(:item, name: "Item11", organization: organization, on_hand_minimum_quantity: 5) }
  let(:item2) { create(:item, name: "Item 2", organization: organization, on_hand_minimum_quantity: 1) }

  let(:storage_location) { create(:storage_location, organization: organization) }
  let(:item_inventory1) { create(:inventory_item, storage_location: storage_location, quantity: item1.on_hand_minimum_quantity, item: item1) }
  let(:item_inventory2) { create(:inventory_item, storage_location: storage_location, quantity: item2.on_hand_minimum_quantity, item: item2) }

  describe "#error" do
    let(:kit) do
      kit_creation_service = KitCreateService.new(organization_id: organization.id, kit_params: params).tap(&:call)
      kit_creation_service.kit
    end
    let(:kit_item_inventory) { InventoryItem.find_by(storage_location_id: storage_location.id, item_id: kit.item.id) }

    context "when the storage location organization doesn't match" do
      let(:wrong_storage) { create(:storage_location) }
      let(:params) do
        {
          organization_id: organization.id,
          name: Faker::Appliance.name,
          line_items_attributes: {
            "0": { item_id: item1.id, quantity: 5 }
          }
        }
      end

      it "returns error" do
        service = DeallocateKitInventoryService.new(kit: kit, storage_location: wrong_storage, decrease_by: 1).deallocate
        expect(service.error).to include("Storage location kit doesn't match")
      end
    end
  end

  describe "#deallocate" do
    let(:kit) do
      kit_creation_service = KitCreateService.new(organization_id: organization.id, kit_params: params).tap(&:call)
      kit_creation_service.kit
    end
    let(:kit_item_inventory) { InventoryItem.find_by(storage_location_id: storage_location.id, item_id: kit.item.id) }

    before do
      # Force there to be kit quantity
      kit_item_inventory.update(quantity: 100)
    end

    context "when inventory items are available" do
      let(:decrease_by) { 2 }
      let(:quantity_of_items1) { 2 }
      let(:quantity_of_items2) { 2 }
      let(:params) do
        {
          organization_id: organization.id,
          name: Faker::Appliance.name,
          line_items_attributes: {
            "0": { item_id: item1.id, quantity: quantity_of_items1 },
            "1": { item_id: item2.id, quantity: quantity_of_items2 }
          }
        }
      end

      it "increases the quantity of the loose items contained in the kit and decrease kit quantity" do
        before_deallocate1 = item_inventory1.quantity
        before_deallocate2 = item_inventory2.quantity
        kit_item_inventory_quantity = kit_item_inventory.quantity

        service = DeallocateKitInventoryService.new(kit: kit, storage_location: storage_location, decrease_by: decrease_by).deallocate

        expect(service.error).to be_nil

        expect(item_inventory1.reload.quantity).to eq(before_deallocate1 + (quantity_of_items1 * decrease_by))
        expect(item_inventory2.reload.quantity).to eq(before_deallocate2 + (quantity_of_items2 * decrease_by))
        expect(kit_item_inventory.reload.quantity).to eq(kit_item_inventory_quantity - decrease_by)
      end
    end
  end
end
