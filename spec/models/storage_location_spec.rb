# == Schema Information
#
# Table name: storage_locations
#
#  id              :integer          not null, primary key
#  address         :string
#  latitude        :float
#  longitude       :float
#  name            :string
#  square_footage  :integer
#  warehouse_type  :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#

RSpec.describe StorageLocation, type: :model do
  context "Validations >" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:address) }
    it { is_expected.to validate_presence_of(:organization) }
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
    let!(:item) { create(:item) }
    subject { create(:storage_location, :with_items, item_quantity: 10, item: item, organization: @organization) }

    describe "increase_inventory" do
      context "With existing inventory" do
        let(:donation) { create(:donation, :with_items, item_quantity: 66, organization: @organization) }

        it "increases inventory quantities from an itemizable object" do
          expect do
            subject.increase_inventory(donation.to_a)
          end.to change { subject.size }.by(66)
        end
      end

      context "when providing a new item that does not yet exist" do
        let(:mystery_item) { create(:item, organization: @organization) }
        let(:donation_with_new_items) { create(:donation, :with_items, organization: @organization, item_quantity: 10, item: mystery_item) }

        it "creates those new inventory items in the storage location" do
          expect do
            subject.increase_inventory(donation_with_new_items.to_a)
          end.to change { subject.inventory_items.count }.by(1)
        end
      end

      context "when increasing with an inactive item" do
        let(:inactive_item) { create(:item, active: false, organization: @organization) }
        let(:donation_with_inactive_item) { create(:donation, :with_items, organization: @organization, item_quantity: 10, item: inactive_item) }

        it "re-activates the item as part of the creation process" do
          expect do
            subject.increase_inventory(donation_with_inactive_item.to_a)
          end.to change { subject.inventory_items.count }.by(1)
                                                         .and change { Item.count }.by(1)
        end
      end
    end

    describe "decrease_inventory" do
      let(:item) { create(:item) }
      let(:distribution) { create(:distribution, :with_items, item: item, item_quantity: 66) }

      it "decreases inventory quantities from an itemizable object" do
        storage_location = create(:storage_location, :with_items, item_quantity: 100, item: item, organization: @organization)
        expect do
          storage_location.decrease_inventory(distribution.to_a)
        end.to change { storage_location.size }.by(-66)
      end

      context "when there is insufficient inventory available" do
        let(:distribution_but_too_much) { create(:distribution, :with_items, item: item, item_quantity: 9001) }

        it "gives informative errors" do
          storage_location = create(:storage_location, :with_items, item_quantity: 10, item: item, organization: @organization)
          expect do
            storage_location.decrease_inventory(distribution_but_too_much.to_a).errors
          end.to raise_error(Errors::InsufficientAllotment)
        end

        it "does not change inventory quantities if there is an error" do
          storage_location = create(:storage_location, :with_items, item_quantity: 10, item: item, organization: @organization)
          starting_size = storage_location.size
          begin
            storage_location.decrease_inventory(distribution.to_a)
          rescue Errors::InsufficientAllotment
          end
          storage_location.reload
          expect(storage_location.size).to eq(starting_size)
        end
      end
    end

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

    describe "inventory_total_value_in_dollars" do
      it "returns total value of all items in this storage location" do
        storage_location = create(:storage_location)
        item1 = create(:item, value_in_cents: 1_00)
        item2 = create(:item, value_in_cents: 2_00)
        create(:inventory_item, storage_location_id: storage_location.id, item_id: item1.id, quantity: 10)
        create(:inventory_item, storage_location_id: storage_location.id, item_id: item2.id, quantity: 10)
        expect(storage_location.inventory_total_value_in_dollars).to eq(30)
      end

      it "returns 0 when there are no items in this storage location" do
        storage_location = create(:storage_location)
        expect(storage_location.inventory_total_value_in_dollars).to eq(0)
      end
    end

    describe "import_csv" do
      it "imports storage locations from a csv file" do
        before_import = StorageLocation.count
        import_file_path = Rails.root.join("spec", "fixtures", "storage_locations.csv")
        data = File.read(import_file_path, encoding: "BOM|UTF-8")
        csv = CSV.parse(data, headers: true)
        StorageLocation.import_csv(csv, @organization.id)
        expect(StorageLocation.count).to eq before_import + 1
      end
    end

    describe "import_inventory" do
      it "imports storage locations from a csv file" do
        donations_count = Donation.count
        storage_location = create(:storage_location, organization_id: @organization.id)
        import_file_path = Rails.root.join("spec", "fixtures", "inventory.csv").read
        StorageLocation.import_inventory(import_file_path, @organization.id, storage_location.id)
        expect(storage_location.size).to eq 14_842
        expect(donations_count).to eq Donation.count
        expect(@organization.adjustments.last.user_id).to eq(@organization.users.find_by(organization_admin: true).id)
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
end
