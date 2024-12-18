RSpec.describe View::Inventory do
  let(:organization) { create(:organization) }
  let!(:storage_location1) { create(:storage_location, name: "SL1", organization: organization) }
  let!(:storage_location2) { create(:storage_location, name: "SL2", organization: organization) }
  let(:item1) { create(:item, name: "Item XYZ", value_in_cents: 120, organization: organization) }
  let(:item2) { create(:item, name: "Item ABC", value_in_cents: 215, organization: organization) }
  let(:item3) { create(:item, name: "Item 3", value_in_cents: 360, organization: organization) }
  before(:each) do
    TestInventory.create_inventory(organization,
      {
        storage_location1.id => {
          item1.id => 100,
          item2.id => 200,
          item3.id => 300
        },
        storage_location2.id => {
          item1.id => 600,
          item2.id => 25
        }
      })
  end
  subject { described_class.new(organization.id) }

  describe "#storage_location_name" do
    it "should return the right name" do
      expect(subject.storage_location_name(storage_location2.id)).to eq("SL2")
    end
  end

  describe ".items_for_location" do
    it "should return the right values" do
      results = described_class.items_for_location(storage_location1)
      expect(results.length).to eq(3)
      expect(results[0].item_id).to eq(item3.id)
      expect(results[0].name).to eq("Item 3")
      expect(results[0].quantity).to eq(300)
      expect(results[1].item_id).to eq(item2.id)
      expect(results[1].name).to eq("Item ABC")
      expect(results[1].quantity).to eq(200)
      expect(results[2].item_id).to eq(item1.id)
      expect(results[2].name).to eq("Item XYZ")
      expect(results[2].quantity).to eq(100)
    end

    context "with include_omitted_items" do
      it "should add items not in the storage location" do
        results = described_class.items_for_location(storage_location2, include_omitted: true)
        expect(results.length).to eq(3)
        expect(results[0].item_id).to eq(item3.id)
        expect(results[0].name).to eq("Item 3")
        expect(results[0].quantity).to eq(0)
        expect(results[1].item_id).to eq(item2.id)
        expect(results[1].name).to eq("Item ABC")
        expect(results[1].quantity).to eq(25)
        expect(results[2].item_id).to eq(item1.id)
        expect(results[2].name).to eq("Item XYZ")
        expect(results[2].quantity).to eq(600)
      end
    end
  end

  describe "#items_for_location" do
    it "should return the right values" do
      results = subject.items_for_location(storage_location1.id)
      expect(results.length).to eq(3)
      expect(results[0].item_id).to eq(item3.id)
      expect(results[0].name).to eq("Item 3")
      expect(results[0].quantity).to eq(300)
      expect(results[1].item_id).to eq(item2.id)
      expect(results[1].name).to eq("Item ABC")
      expect(results[1].quantity).to eq(200)
      expect(results[2].item_id).to eq(item1.id)
      expect(results[2].name).to eq("Item XYZ")
      expect(results[2].quantity).to eq(100)
    end

    context "with include_omitted_items" do
      it "should add items not in the storage location" do
        results = subject.items_for_location(storage_location2.id, include_omitted: true)
        expect(results.length).to eq(3)
        expect(results[0].item_id).to eq(item3.id)
        expect(results[0].name).to eq("Item 3")
        expect(results[0].quantity).to eq(0)
        expect(results[1].item_id).to eq(item2.id)
        expect(results[1].name).to eq("Item ABC")
        expect(results[1].quantity).to eq(25)
        expect(results[2].item_id).to eq(item1.id)
        expect(results[2].name).to eq("Item XYZ")
        expect(results[2].quantity).to eq(600)
      end
    end
  end

  describe ".total_inventory" do
    it "should return the total quantity" do
      expect(described_class.total_inventory(organization.id)).to eq(1225)
    end
  end

  describe "#quantity_for" do
    context "with item id" do
      context "with no storage location" do
        it "should return quantities across all storage locations" do
          expect(subject.quantity_for(item_id: item1.id)).to eq(700)
        end
      end
      context "with storage location" do
        it "should return the quantity at that location" do
          expect(subject.quantity_for(item_id: item1.id, storage_location: storage_location1.id)).to eq(100)
        end
      end
    end
    context "with storage location but no item id" do
      it "should return all items at that location" do
        expect(subject.quantity_for(storage_location: storage_location1.id)).to eq(600)
      end
    end
  end

  describe "#storage_locations_for_item" do
    it "should return all relevant IDs" do
      expect(subject.storage_locations_for_item(item1.id))
        .to contain_exactly(storage_location1.id, storage_location2.id)
      expect(subject.storage_locations_for_item(item3.id))
        .to contain_exactly(storage_location1.id)
    end
  end

  describe "#total_value_in_dollars" do
    it "should return total value across the given location" do
      expect(subject.total_value_in_dollars(storage_location: storage_location2.id)).to eq(773.75)
    end
  end

  describe "#all_items" do
    it "should return all items across storage locations" do
      results = subject.all_items
      expect(results.size).to eq(5)
      expect(results.count { |i| i.storage_location_id == storage_location1.id }).to eq(3)
      expect(results.count { |i| i.storage_location_id == storage_location2.id }).to eq(2)
      expect(results.count { |i| i.item_id == item1.id }).to eq(2)
      expect(results.count { |i| i.item_id == item2.id }).to eq(2)
      expect(results.count { |i| i.item_id == item3.id }).to eq(1)
    end
  end
end
