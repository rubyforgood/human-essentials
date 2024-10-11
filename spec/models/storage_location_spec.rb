# == Schema Information
#
# Table name: storage_locations
#
#  id              :integer          not null, primary key
#  address         :string
#  discarded_at    :datetime
#  latitude        :float
#  longitude       :float
#  name            :string
#  square_footage  :integer
#  time_zone       :string           default("America/Los_Angeles"), not null
#  warehouse_type  :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#
RSpec.describe StorageLocation, type: :model do
  let(:organization) { create(:organization) }

  context "Validations >" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:address) }
    it { is_expected.to validate_presence_of(:organization) }
  end

  context "Callbacks >" do
    describe "before_destroy" do
      let(:item) { create(:item, organization: organization) }
      subject { create(:storage_location, :with_items, item_quantity: 10, item: item, organization: organization) }

      it "does not delete storage locations with inventory items on it" do
        subject.destroy

        expect(subject.errors.messages[:base]).to include("Cannot delete storage location containing inventory items with non-zero quantities")
      end

      it "deletes storage locations with no inventory items on it" do
        TestInventory.clear_inventory(subject)
        subject.destroy

        expect(StorageLocation.count).to eq(0)
      end
    end
  end

  context "Filtering >" do
    it "->active_locations yields only storage locations that haven't been discarded" do
      create(:storage_location, name: "Active Location")
      create(:storage_location, name: "Inactive Location", discarded_at: Time.zone.now)
      results = StorageLocation.active_locations
      expect(results.length).to eq(1)
      expect(results.first.discarded_at).to be_nil
    end
  end

  context "Methods >" do
    let(:item) { create(:item) }
    subject { create(:storage_location, :with_items, item_quantity: 10, item: item, organization: organization) }

    describe "StorageLocation.items_inventoried" do
      it "returns a collection of items that are stored within inventories" do
        items = create_list(:item, 3, organization: organization)
        create(:storage_location, :with_items, item: items[0], item_quantity: 5, organization: organization)
        create(:storage_location, :with_items, item: items[2], item_quantity: 5, organization: organization)
        expect(StorageLocation.items_inventoried(organization).length).to eq(2)
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
        TestInventory.create_inventory(storage_location.organization, {
          storage_location.id => {
            create(:item).id => 10,
            create(:item).id => 10
          }
        })
        expect(storage_location.size).to eq(20)
      end
    end

    describe "inventory_total_value_in_dollars" do
      it "returns total value of all items in this storage location" do
        storage_location = create(:storage_location)
        item1 = create(:item, value_in_cents: 1_00)
        item2 = create(:item, value_in_cents: 2_00)
        TestInventory.create_inventory(storage_location.organization, {
          storage_location.id => {
            item1.id => 10,
            item2.id => 10
          }
        })
        expect(storage_location.inventory_total_value_in_dollars).to eq(30)
      end

      it "returns a value including cents if the total isn't an even dollar amount" do
        storage_location = create(:storage_location)
        item1 = create(:item, value_in_cents: 1_15)
        TestInventory.create_inventory(storage_location.organization, {
          storage_location.id => {
            item1.id => 5
          }
        })
        expect(storage_location.inventory_total_value_in_dollars).to eq(5.75)
      end

      it "returns 0 when there are no items in this storage location" do
        storage_location = create(:storage_location)
        expect(storage_location.inventory_total_value_in_dollars).to eq(0)
      end
    end

    describe "import_csv" do
      it "imports storage locations from a csv file" do
        before_import = StorageLocation.count
        import_file_path = Rails.root.join("spec", "fixtures", "files", "storage_locations.csv")
        data = File.read(import_file_path, encoding: "BOM|UTF-8")
        csv = CSV.parse(data, headers: true)
        StorageLocation.import_csv(csv, organization.id)
        expect(StorageLocation.count).to eq before_import + 1
      end
    end

    describe "import_inventory" do
      # org must be seeded with items for csv items to be importable
      let(:organization) { create(:organization, :with_items) }

      it "imports storage locations from a csv file" do
        # import inventory requires an admin user
        # adjustment will be created by the first user with the ORG_ADMIN role
        user = create(:organization_admin, organization: organization)

        donations_count = Donation.count
        storage_location = create(:storage_location, organization: organization)
        import_file_path = Rails.root.join("spec", "fixtures", "files", "inventory.csv").read

        StorageLocation.import_inventory(import_file_path, organization.id, storage_location.id)

        expect(storage_location.size).to eq 14_842
        expect(donations_count).to eq Donation.count
        expect(organization.adjustments.last.user_id).to eq(user.id)
      end

      it "raises an error if there are already items" do
        item1 = create(:item, organization: organization)
        item2 = create(:item, organization: organization)
        item3 = create(:item, organization: organization)
        storage_location_with_items = create(:storage_location, organization: organization)

        TestInventory.create_inventory(organization,
         {
           storage_location_with_items.id => {
             item1.id => 30,
             item2.id => 10,
             item3.id => 40
           }
         })

        import_file_path = Rails.root.join("spec", "fixtures", "files", "inventory.csv").read

        expect do
          StorageLocation.import_inventory(import_file_path, organization.id, storage_location_with_items.id)
        end.to raise_error(Errors::InventoryAlreadyHasItems)
      end
    end

    describe "geocode" do
      it "adds coordinates to the database" do
        storage_location = build(:storage_location,
                                 "address" => "1500 Remount Road, Front Royal, VA 22630")
        storage_location.save
        expect(storage_location.latitude).not_to eq(nil)
        expect(storage_location.longitude).not_to eq(nil)
      end
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
