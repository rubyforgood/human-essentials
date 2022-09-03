RSpec.describe AllocateKitInventoryService, type: :service do
  let(:organization) { create :organization }
  let(:item) { create(:item, name: "Item", organization: organization, on_hand_minimum_quantity: 5) }
  let(:item_out_of_stock) { create(:item, name: "Item out of stock", organization: organization, on_hand_minimum_quantity: 0) }

  let(:storage_location) { create(:storage_location, organization: organization) }
  let(:item_inventory) { create(:inventory_item, storage_location: storage_location, quantity: item.on_hand_minimum_quantity, item: item) }
  let(:item_out_of_stock_inventory) { create(:inventory_item, storage_location: storage_location, quantity: item_out_of_stock.on_hand_minimum_quantity, item: item_out_of_stock) }

  describe "#error" do
    let(:kit) { Kit.create(params) }

    context "when the Store location organization doesn't match" do
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
        service = AllocateKitInventoryService.new(kit: kit, storage_location: wrong_storage, increase_by: 1).allocate
        expect(service.error).to include("Storage location kit doesn't match")
      end
    end
  end

  describe "#allocate" do
    let(:kit) do
      kit_creation_service = KitCreateService.new(organization_id: organization.id, kit_params: params).tap(&:call)
      kit_creation_service.kit
    end
    let(:kit_item_inventory) { InventoryItem.find_by(storage_location_id: storage_location.id, item_id: kit.item.id) }

    context "when inventory items are available" do
      let(:quantity_of_items) { 1 }
      let(:increase_by) { 2 }
      let(:params) do
        {
          organization_id: organization.id,
          name: Faker::Appliance.equipment,
          line_items_attributes: {
            "0": { item_id: item.id, quantity: quantity_of_items }
          }
        }
      end

      it "allocates items and increases the quantity of the Kit Item" do
        quantity_before_allocate = item_inventory.quantity
        kit_quantity_before_allocate = kit_item_inventory.quantity

        service = AllocateKitInventoryService.new(kit: kit, storage_location: storage_location, increase_by: increase_by).allocate

        # Check to see that the correct amount of the associated item
        # had decreased in quantity
        expect(item_inventory.reload.quantity).to eq(quantity_before_allocate - (quantity_of_items * increase_by))

        # Check that the kit's item quantity was increased by the correct amount
        expect(kit_item_inventory.reload.quantity).to eq(kit_quantity_before_allocate + increase_by)

        expect(service.error).to be_nil
      end
    end

    context "when more than one kit is requested" do
      let(:params) do
        {
          organization_id: organization.id,
          name: Faker::Appliance.equipment,
          line_items_attributes: {
            "0": { item_id: item.id, quantity: quantity_of_items }
          }
        }
      end

      context "but one of the items is out of stock" do
        let(:quantity_of_items) { item_inventory.quantity }
        let(:quantity_of_kits) { 2 }

        it "returns error and does not change kit or item quantity" do
          kit_quantity_before_allocate = kit_item_inventory.quantity

          service = AllocateKitInventoryService.new(kit: kit, storage_location: storage_location, increase_by: quantity_of_kits).allocate

          expect(service.error).to include("Requested items exceed the available inventory")

          expect(item_inventory.reload.quantity).to eq(quantity_of_items)
          expect(kit_item_inventory.reload.quantity).to eq(kit_quantity_before_allocate)
        end
      end
    end
  end
end
