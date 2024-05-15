RSpec.describe AllocateKitInventoryService, type: :service do
  let(:organization) { create(:organization) }
  let(:item) { create(:item, name: "Item", organization: organization, on_hand_minimum_quantity: 15) }
  let(:item_out_of_stock) { create(:item, name: "Item out of stock", organization: organization, on_hand_minimum_quantity: 0) }

  let(:storage_location) { create(:storage_location, organization: organization) }
  let(:item_inventory) { storage_location.inventory_items.where(item_id: item.id).first }
  let(:item_out_of_stock_inventory) { storage_location.inventory_items.where(item_id: item_out_of_stock.id)&.first }

  before(:each) do
    TestInventory.create_inventory(organization, {
      storage_location.id => {
        item.id => 15,
        item_out_of_stock.id => 0
      }
    })
  end

  describe "#error" do
    let(:kit) { Kit.create(params) }

    context "when the Store location organization doesn't match" do
      let(:wrong_organization) { create(:organization) }
      let(:wrong_storage) { create(:storage_location, organization: wrong_organization) }
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
    let(:inventory_out) {
      KitAllocation.find_by(storage_location_id: storage_location.id, kit_id: kit.id,
        organization_id: kit.organization.id, kit_allocation_type: "inventory_out")
    }
    let(:inventory_in) {
      KitAllocation.find_by(storage_location_id: storage_location.id, kit_id: kit.id,
        organization_id: kit.organization.id, kit_allocation_type: "inventory_in")
    }

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

      it "allocates items, increases the quantity of the Kit Item and inventory in, and decreases inventory out" do
        quantity_before_allocate = item_inventory.quantity
        kit_quantity_before_allocate = kit_item_inventory.quantity

        service = AllocateKitInventoryService.new(kit: kit, storage_location: storage_location, increase_by: increase_by).allocate

        # Check to see that the correct amount of the associated item
        # had decreased in quantity
        expect(item_inventory.reload.quantity).to eq(quantity_before_allocate - (quantity_of_items * increase_by))

        # Check that the kit's item quantity was increased by the correct amount
        expect(kit_item_inventory.reload.quantity).to eq(kit_quantity_before_allocate + increase_by)
        inventory = View::Inventory.new(organization.id)
        expect(inventory.quantity_for(storage_location: storage_location.id, item_id: item.id)).to eq(13)
        expect(inventory.quantity_for(storage_location: storage_location.id, item_id: kit.item.id)).to eq(2)

        # Check that Inventory out decreased by allocated kit's line_items and their respective quantities
        expect(inventory_out.line_items.count).to eq(kit.line_items.count)
        expect(inventory_out.line_items.first.item_id).to eq(kit.line_items.first.item_id)
        expect(inventory_out.line_items.first.quantity).to eq(kit.line_items.first.quantity * -increase_by)

        # Check inventory in increased by number of kits allocated
        expect(inventory_in.line_items.first.quantity).to eq(increase_by)

        expect(service.error).to be_nil
      end

      context "When kit is allocated more then once" do
        let(:second_increase_by) { 3 }

        before do
          item_inventory
          @first_call = AllocateKitInventoryService.new(kit: kit, storage_location: storage_location, increase_by: increase_by).allocate
          @second_call = AllocateKitInventoryService.new(kit: kit, storage_location: storage_location, increase_by: second_increase_by).allocate
        end

        it "increases the already existed inventory in and decreases the already existed inventory out" do
          expect(@first_call.error).to be_nil
          expect(@second_call.error).to be_nil

          # Check inventory out decreases both time with the increase_by value
          expect(inventory_out.line_items.first.quantity).to eq(kit.line_items.first.quantity * -(increase_by + second_increase_by))

          # Check inventory in increase both time with increase_by value
          expect(inventory_in.line_items.first.quantity).to eq(increase_by + second_increase_by)
        end
      end

      context "when there are more then one line items" do
        let(:params) do
          {
            organization_id: organization.id,
            name: Faker::Appliance.equipment,
            line_items_attributes: {
              "0": { item_id: item.id, quantity: quantity_of_items },
              "1": { item_id: item.id, quantity: 2 }
            }
          }
        end

        context "when there kit is allocated once" do
          before do
            item_inventory
            @first_call = AllocateKitInventoryService.new(kit: kit, storage_location: storage_location, increase_by: increase_by).allocate
          end

          it "inventory out for that kit contains both line_items with their respective quantity" do
            expect(inventory_out.line_items[0].quantity).to eq(kit.line_items[0].quantity * -increase_by)
            expect(inventory_out.line_items[1].quantity).to eq(kit.line_items[1].quantity * -increase_by)
          end
        end

        context "when same kit is allocated multiple times" do
          let(:second_increase_by) { 3 }
          before do
            item_inventory
            @first_call = AllocateKitInventoryService.new(kit: kit, storage_location: storage_location, increase_by: increase_by).allocate
            @second_call = AllocateKitInventoryService.new(kit: kit, storage_location: storage_location, increase_by: second_increase_by).allocate
          end

          it "inventory out for that kit contains both line_items with their respective quantity" do
            expect(@first_call.error).to be_nil
            expect(@second_call.error).to be_nil

            expect(inventory_in.line_items.first.quantity).to eq(increase_by + second_increase_by)
            expect(inventory_out.line_items[0].quantity).to eq(kit.line_items[0].quantity * -(increase_by + second_increase_by))
            expect(inventory_out.line_items[1].quantity).to eq(kit.line_items[1].quantity * -(increase_by + second_increase_by))
          end
        end
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

          message = Event.read_events?(organization) ? "Could not reduce quantity" : "items exceed the available inventory"
          expect(service.error).to include(message)

          expect(item_inventory.reload.quantity).to eq(quantity_of_items)
          expect(kit_item_inventory.reload.quantity).to eq(kit_quantity_before_allocate)
          inventory = View::Inventory.new(organization.id)
          expect(inventory.quantity_for(storage_location: storage_location.id, item_id: item.id)).to eq(quantity_of_items)
          expect(inventory.quantity_for(storage_location: storage_location.id, item_id: kit.item.id)).to eq(kit_quantity_before_allocate)
        end
      end
    end
  end
end
