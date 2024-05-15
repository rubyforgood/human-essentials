RSpec.describe DeallocateKitInventoryService, type: :service do
  let(:organization) { create(:organization) }
  let(:item1) { create(:item, name: "Item11", organization: organization, on_hand_minimum_quantity: 5) }
  let(:item2) { create(:item, name: "Item 2", organization: organization, on_hand_minimum_quantity: 1) }

  let(:storage_location) { create(:storage_location, organization: organization) }
  let(:item_inventory1) { storage_location.inventory_items.find_by(item_id: item1.id) }
  let(:item_inventory2) { storage_location.inventory_items.find_by(item_id: item2.id) }

  let(:inventory_in) { create(:kit_allocation, storage_location: storage_location, organization_id: organization.id, kit_id: kit.id, kit_allocation_type: "inventory_in") }
  let(:inventory_out) { create(:kit_allocation, storage_location: storage_location, organization_id: organization.id, kit_id: kit.id, kit_allocation_type: "inventory_out") }

  before(:each) do
    TestInventory.create_inventory(organization, {
      storage_location.id => {
        item1.id => 5,
        item2.id => 1
      }
    })
  end

  describe "#error" do
    let(:kit) do
      kit_creation_service = KitCreateService.new(organization_id: organization.id, kit_params: params).tap(&:call)
      kit_creation_service.kit
    end
    let(:kit_item_inventory) { InventoryItem.find_by(storage_location_id: storage_location.id, item_id: kit.item.id) }

    context "when the storage location organization doesn't match" do
      let(:wrong_organization) { create(:organization) }
      let(:wrong_storage) { create(:storage_location, organization: wrong_organization) }
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
      TestInventory.create_inventory(organization,
        {
          storage_location.id => {
            kit.item.id => 100
          }
        })
    end

    context "when inventory items are available" do
      let(:decrease_by) { 2 }
      let(:quantity_of_items1) { 2 }
      let(:quantity_of_items2) { 3 }
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

      context "when  decrease_by is equal to kit's quantity in inventory_in" do
        before do
          inventory_out.line_items.create!(item_id: item1.id, quantity: -1 * (quantity_of_items1 * decrease_by))
          inventory_out.line_items.create!(item_id: item2.id, quantity: -1 * (quantity_of_items2 * decrease_by))
          inventory_in.line_items.create!(item_id: kit.item.id, quantity: decrease_by)
        end

        it "increases the quantity of the loose items contained in the kit and decrease kit quantity, and delete inventory_in and inventory_out" do
          before_deallocate1 = item_inventory1.quantity
          before_deallocate2 = item_inventory2.quantity
          kit_item_inventory_quantity = kit_item_inventory.quantity
          service = DeallocateKitInventoryService.new(kit: kit, storage_location: storage_location, decrease_by: decrease_by).deallocate

          expect(service.error).to be_nil

          expect(item_inventory1.reload.quantity).to eq(before_deallocate1 + (quantity_of_items1 * decrease_by))
          expect(item_inventory2.reload.quantity).to eq(before_deallocate2 + (quantity_of_items2 * decrease_by))
          expect(kit_item_inventory.reload.quantity).to eq(kit_item_inventory_quantity - decrease_by)
          inventory = View::Inventory.new(organization.id)
          expect(inventory.quantity_for(storage_location: storage_location.id, item_id: item1.id))
            .to eq(before_deallocate1 + (quantity_of_items1 * decrease_by))
          expect(inventory.quantity_for(storage_location: storage_location.id, item_id: item2.id))
            .to eq(before_deallocate2 + (quantity_of_items2 * decrease_by))
          expect(inventory.quantity_for(storage_location: storage_location.id, item_id: kit.item.id))
            .to eq(kit_item_inventory_quantity - decrease_by)

          # Invetory out and inventory in should be deleted on de-allocation
          expect(KitAllocation.find_by(id: inventory_in.id).present?).to be_falsey
          expect(KitAllocation.find_by(id: inventory_out.id).present?).to be_falsey
        end
      end

      context "when decrease_by is less then kit's quantity in inventory_in" do
        let(:inventory_quantity) { 3 }
        before do
          inventory_out.line_items.create!(item_id: item1.id, quantity: -1 * (quantity_of_items1 * inventory_quantity))
          inventory_out.line_items.create!(item_id: item2.id, quantity: -1 * (quantity_of_items2 * inventory_quantity))
          inventory_in.line_items.create!(item_id: kit.item.id, quantity: inventory_quantity)
        end

        it "will add items in inventory_out and remove kits for decrease_by from inventory_in" do
          first_line_item_quantity_before = inventory_out.reload.line_items[0].quantity
          second_line_item_quantity_before = inventory_out.reload.line_items[1].quantity
          kit_quantity = inventory_in.reload.line_items.first.quantity
          service = DeallocateKitInventoryService.new(kit: kit, storage_location: storage_location, decrease_by: decrease_by).deallocate

          expect(service.error).to be_nil

          # inventoy out increased with decrease_by
          expect(inventory_out.reload.line_items[0].quantity).to eq(first_line_item_quantity_before + (quantity_of_items1 * decrease_by))
          expect(inventory_out.reload.line_items[1].quantity).to eq(second_line_item_quantity_before + (quantity_of_items2 * decrease_by))

          # invetory in decreased with decrease_by
          expect(inventory_in.reload.line_items.first.quantity).to eq(kit_quantity - decrease_by)
        end
      end

      context "when decrease_by is greater then kit's quantity in inventory_in" do
        before do
          inventory_out.line_items.create!(item_id: item1.id, quantity: -1 * quantity_of_items1)
          inventory_out.line_items.create!(item_id: item2.id, quantity: -1 * quantity_of_items2)
          inventory_in.line_items.create!(item_id: kit.item.id, quantity: 1)
        end

        it "raises error about inconsistent inventory in or out" do
          service = DeallocateKitInventoryService.new(kit: kit, storage_location: storage_location, decrease_by: decrease_by).deallocate

          expect(service.error).to eq("Inconsistent inventory in")
        end
      end

      context "when kit_allocation not exist for inventory_in or inventory_out" do
        let(:inventory_in) { nil }
        let(:inventory_out) { nil }

        it "raises error about KitAllocation not found" do
          service = DeallocateKitInventoryService.new(kit: kit, storage_location: storage_location, decrease_by: decrease_by).deallocate
          expect(service.error).to eq("KitAllocation not found for given kit")
        end
      end
    end
  end
end
