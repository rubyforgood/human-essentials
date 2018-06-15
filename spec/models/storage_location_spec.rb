# == Schema Information
#
# Table name: storage_locations
#
#  id              :bigint(8)        not null, primary key
#  name            :string
#  address         :string
#  created_at      :datetime
#  updated_at      :datetime
#  organization_id :integer
#

RSpec.describe StorageLocation, type: :model do
  let(:organization) { create(:organization) }

  context "Validations >" do
    it "requires a name" do
      expect(build(:storage_location, name: nil)).not_to be_valid
    end
    it "requires an address" do
      expect(build(:storage_location, address: nil)).not_to be_valid
    end
  end

  context "Filtering >" do
    it "->containing yields only inventories that have that item" do
      item = create(:item)
      item2 = create(:item)
      storage_location = create(:storage_location, :with_items, item: item, item_quantity: 5)
      create(:storage_location, :with_items, item: item2, item_quantity: 5)
      results = StorageLocation.containing(item.id)
      expect(results.length).to eq(1)
      expect(results.first).to eq(storage_location)
    end
  end

  context "Methods >" do
    describe "StorageLocation.item_total" do
      it "gathers the final total of a single item across all inventories" do
        item = create(:item)
        storage_location = create(:storage_location, :with_items, item_quantity: 10, item: item)
        create(:storage_location, :with_items, item_quantity: 10, item: item)
        # This inventory_item will not be included, because it will be for a different item
        create(:inventory_item, storage_location_id: storage_location.id, quantity: 10)

        expect(StorageLocation.item_total(item.id)).to eq(20)
      end
    end

    describe "StorageLocation.items_inventoried" do
      it "returns a collection of items that are stored within inventories" do
        create_list(:item, 3)
        create(:storage_location, :with_items, item: Item.first, item_quantity: 5)
        create(:storage_location, :with_items, item: Item.last, item_quantity: 5)
        expect(StorageLocation.items_inventoried.length).to eq(2)
      end
    end

    describe "item_total" do
      it "retrieves the total for a single item" do
        item = create(:item)
        storage_location = create(:storage_location, :with_items, item_quantity: 10, item: item)
        expect(storage_location.item_total(item.id)).to eq(10)
      end
    end

    describe "size" do
      it "returns total quantity of all items in this storage location" do
        storage_location = create(:storage_location)
        create(:inventory_item, storage_location_id: storage_location.id, quantity: 10)
        create(:inventory_item, storage_location_id: storage_location.id, quantity: 10)
        expect(storage_location.size).to eq(20)
      end
    end

    describe "intake!" do
      it "adds items to a storage location even if none exist" do
        storage_location = create(:storage_location)
        donation = create(:donation, :with_items, item_quantity: 10)
        expect do
          storage_location.intake!(donation)
          storage_location.items.reload
        end.to change { storage_location.items.count }.by(1)
        expect(storage_location.size).to eq(10)
      end

      it "adds items to the storage location total if that item already exists in inventory" do
        storage_location = create(:storage_location, :with_items, item_quantity: 10)
        donation = create(:donation, :with_items, item_quantity: 10, item: storage_location.inventory_items.first.item)
        storage_location.intake!(donation)

        expect(storage_location.inventory_items.count).to eq(1)
        expect(storage_location.inventory_items.where(item_id: donation.line_items.first.item).first.quantity).to eq(20)
      end
    end

    describe "remove!" do
      let(:storage_location) { create(:storage_location) }
      let(:donation)         { create(:donation, :with_items, item_quantity: 10) }

      before(:each) do
        storage_location.intake!(donation)
        storage_location.items.reload

        expect(storage_location.size).to eq(10)
        expect(storage_location.items.count).to eq(1)
      end

      it "removes items from a storage location" do
        expect do
          storage_location.remove!(donation)
        end.to change { storage_location.size }.by(-donation.total_quantity)
                                               .and change { storage_location.inventory_items.size }.by(-donation.line_items.count)
                                                                                                    .and change { InventoryItem.count }.by(-donation.line_items.count)
      end
    end

    describe "adjust_from_past!" do
      let(:storage_location) { create(:storage_location) }
      let(:purchase)         { create(:purchase, :with_items, item_quantity: 10) }
      let(:donation)         { create(:donation, :with_items, item_quantity: 10) }

      context "with_donations" do
        before(:each) do
          storage_location.intake!(donation)
        end

        it "updates the quantity of items" do
          previous_quantities = donation.line_items_quantities
          donation.line_items.first.update(quantity: 5)
          expect do
            storage_location.adjust_from_past!(donation, previous_quantities)
            storage_location.reload
          end.to change { storage_location.size }.by(-5)
        end

        it "removes the inventory item from the DB if the item's removal results in a 0 count" do
          previous_quantities = donation.line_items_quantities
          donation.line_items.first.update(quantity: 0)

          expect do
            storage_location.adjust_from_past!(donation, previous_quantities)
            storage_location.reload
          end.to change { storage_location.inventory_items.size }.by(-1)
                                                                 .and change { InventoryItem.count }.by(-1)
        end
      end
      context "With purchases" do
        before(:each) do
          storage_location.intake!(purchase)
          storage_location.items.reload
        end

        it "removes the inventory item from the DB if the item's removal results in a 0 count" do
          previous_quantities = purchase.line_items_quantities
          purchase.line_items.first.update(quantity: 0)

          expect do
            storage_location.adjust_from_past!(purchase, previous_quantities)
            storage_location.reload
          end.to change { storage_location.inventory_items.size }.by(-1)
                                                                 .and change { InventoryItem.count }.by(-1)
        end
      end
    end

    describe "distribute!" do
      it "distrbutes items from storage location" do
        storage_location = create :storage_location, :with_items, item_quantity: 300
        distribution = build :distribution, :with_items, storage_location: storage_location, item_quantity: 50
        storage_location.distribute!(distribution)
        expect(storage_location.inventory_items.first.quantity).to eq 250
      end

      it "raises error when distribution exceeds storage location inventory" do
        storage_location = create :storage_location, :with_items, item_quantity: 300
        distribution = build :distribution, :with_items, storage_location: storage_location, item_quantity: 350
        item = distribution.line_items.first.item
        expect do
          storage_location.distribute!(distribution)
        end.to raise_error do |error|
          expect(error).to be_a Errors::InsufficientAllotment
          expect(error.insufficient_items).to include(
            item_id: item.id,
            item_name: item.name,
            quantity_on_hand: 300,
            quantity_requested: 350
          )
        end
      end
    end

    describe "import_csv" do
      it "imports storage locations from a csv file" do
        organization
        before_import = StorageLocation.count
        import_file_path = Rails.root.join("spec", "fixtures", "storage_locations.csv").read
        StorageLocation.import_csv(import_file_path, organization.id)
        expect(StorageLocation.count).to eq before_import + 3
      end
    end

    describe "import_inventory" do
      it "imports storage locations from a csv file" do
        organization
        storage_location = create(:storage_location)
        import_file_path = Rails.root.join("spec", "fixtures", "inventory.csv").read
        StorageLocation.import_inventory(import_file_path, organization.id, storage_location.id)
        expect(storage_location.size).to eq 14_842
      end
    end

    describe "adjust!" do
      it "combines line item quantities with inventory amounts" do
        storage_location = create :storage_location, :with_items, item_quantity: 300
        adjustment = build :adjustment, :with_items, storage_location: storage_location, item_quantity: 50
        storage_location.adjust!(adjustment)
        expect(storage_location.inventory_items.first.quantity).to eq 350

        adjustment2 = build :adjustment, :with_items, storage_location: storage_location, item_quantity: -50
        storage_location.adjust!(adjustment2)
        expect(storage_location.inventory_items.first.quantity).to eq 300
      end
      it "ensures that a user cannot adjust an inventory into the negative" do
        storage_location = create :storage_location, :with_items, item_quantity: 300
        adjustment = build :adjustment, :with_items, storage_location: storage_location, item_quantity: -301
        expect do
          storage_location.adjust!(adjustment)
        end.to raise_error(Errors::InsufficientAllotment)
      end
    end

    describe "move_inventory!" do
      it "removes inventory from a storage location and adds them to another storage location" do
        item = create(:item)
        storage_location = create :storage_location, :with_items, item: item, item_quantity: 300
        storage_location2 = create :storage_location, :with_items, item: item, item_quantity: 100
        transfer = build :transfer, :with_items, item: item, item_quantity: 100,
                                                 from: storage_location, to: storage_location2
        storage_location.move_inventory!(transfer)
        expect(storage_location.inventory_items.first.quantity).to eq 200
        expect(storage_location2.inventory_items.first.quantity).to eq 200
      end

      it "raises error when distribution exceeds inventory in a storage facility" do
        item = create(:item)
        storage_location = create :storage_location, :with_items, item: item, item_quantity: 100
        storage_location2 = create :storage_location, :with_items, item: item, item_quantity: 100
        transfer = build :transfer, :with_items, item: item, item_quantity: 200,
                                                 from_id: storage_location.id, to_id: storage_location2.id
        expect do
          storage_location.move_inventory!(transfer)
        end.to raise_error(Errors::InsufficientAllotment)
      end
    end

    describe "reclaim!" do
      it "adds distribution items back to storage location" do
        storage_location = create :storage_location, :with_items, item_quantity: 300
        distribution = create :distribution, :with_items, storage_location: storage_location, item_quantity: 50
        storage_location.reclaim!(distribution)
        expect(storage_location.inventory_items.first.quantity).to eq 350
      end
    end
  end
end
