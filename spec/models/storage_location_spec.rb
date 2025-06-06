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
    it "ensures that square_footage cannot be negative" do
      expect(build(:storage_location, square_footage: -1)).not_to be_valid
      expect(build(:storage_location, square_footage: 0)).to be_valid
      expect(build(:storage_location, square_footage: 100)).to be_valid
      expect(build(:storage_location, square_footage: nil)).to be_valid
    end
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
    it "->active yields only storage locations that haven't been discarded" do
      create(:storage_location, name: "Active Location")
      create(:storage_location, name: "Inactive Location", discarded_at: Time.zone.now)
      results = StorageLocation.active
      expect(results.length).to eq(1)
      expect(results.first.discarded_at).to be_nil
    end

    it "->with_transfers_to yields storage locations with transfers to an organization" do
      storage_location1 = create(:storage_location, name: "loc1", organization: organization)
      storage_location2 = create(:storage_location, name: "loc2", organization: organization)
      storage_location3 = create(:storage_location, name: "loc3", organization: organization)
      storage_location4 = create(:storage_location, name: "loc4", organization: create(:organization))
      storage_location5 = create(:storage_location, name: "loc5", organization: storage_location4.organization)
      create(:transfer, from: storage_location3, to: storage_location1, organization: organization)
      create(:transfer, from: storage_location3, to: storage_location2, organization: organization)
      create(:transfer, from: storage_location5, to: storage_location4, organization: storage_location4.organization)

      expect(StorageLocation.with_transfers_to(organization).to_a).to match_array([storage_location1, storage_location2])
    end

    it "->with_transfers_from yields storage locations with transfers from an organization" do
      storage_location1 = create(:storage_location, name: "loc1", organization: organization)
      storage_location2 = create(:storage_location, name: "loc2", organization: organization)
      storage_location3 = create(:storage_location, name: "loc3", organization: organization)
      storage_location4 = create(:storage_location, name: "loc4", organization: create(:organization))
      storage_location5 = create(:storage_location, name: "loc5", organization: storage_location4.organization)
      create(:transfer, from: storage_location3, to: storage_location1, organization: organization)
      create(:transfer, from: storage_location3, to: storage_location2, organization: organization)
      create(:transfer, from: storage_location5, to: storage_location4, organization: storage_location4.organization)

      expect(StorageLocation.with_transfers_from(organization).to_a).to match_array([storage_location3])
    end
  end

  context "Scopes >" do
    describe "with_audits_for" do
      it "returns only storage locations that are used for one org" do
        storage_location1 = create(:storage_location, organization: organization)
        storage_location2 = create(:storage_location, organization: organization)
        create(:storage_location, organization: organization)
        storage_location4 = create(:storage_location, organization: create(:organization))
        create(:audit, storage_location: storage_location1, organization: organization)
        create(:audit, storage_location: storage_location2, organization: organization)
        create(:audit, storage_location: storage_location4, organization: storage_location4.organization)
        expect(StorageLocation.with_audits_for(organization).to_a).to match_array([storage_location1, storage_location2])
      end

      it "returns audited storage locations that have been discarded" do
        storage_location1 = create(:storage_location, organization: organization, discarded_at: Time.current)
        create(:storage_location, organization: organization)
        create(:audit, storage_location: storage_location1, organization: organization)
        expect(StorageLocation.with_audits_for(organization).to_a).to match_array([storage_location1])
      end
    end

    describe "with_adjustments_for" do
      it "returns only storage locations that are used in adjustments for one org" do
        storage_location1 = create(:storage_location, organization: organization)
        storage_location2 = create(:storage_location, organization: organization)
        create(:storage_location, organization: organization)
        storage_location4 = create(:storage_location, organization: create(:organization))
        create(:adjustment, storage_location: storage_location1, organization: organization)
        create(:adjustment, storage_location: storage_location2, organization: organization)
        create(:adjustment, storage_location: storage_location4, organization: storage_location4.organization)
        expect(StorageLocation.with_adjustments_for(organization).to_a).to match_array([storage_location1, storage_location2])
      end
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
