RSpec.describe LowInventoryQuery do
  let(:organization) { create :organization }
  let(:storage_location) { create :storage_location, organization: organization }

  let(:minimum_quantity) { 0 }
  let(:recommended_quantity) { 0 }
  let(:current_quantity) { 100 }

  let(:item) do
    create :item,
      organization: organization,
      on_hand_minimum_quantity: minimum_quantity,
      on_hand_recommended_quantity: recommended_quantity
  end

  before :each do
    TestInventory.create_inventory(organization, {storage_location.id => {item.id => current_quantity}})
  end

  context "when minimum_quantity and recommended_quantity are zero" do
    let(:minimum_quantity) { 0 }
    let(:recommended_quantity) { 0 }

    it "should return an empty array" do
      result = LowInventoryQuery.call(organization).map { |r| r.to_h.symbolize_keys }
      expect(result).to be_empty
    end
  end

  context "when minimum_quantity is 0 and recommended_quantity is nil and item quantity is 0" do
    let(:minimum_quantity) { 0 }
    let(:current_quantity) { 0 }

    it "should return an empty array" do
      result = LowInventoryQuery.call(organization).map { |r| r.to_h.symbolize_keys }
      expect(result).to be_empty
    end
  end

  context "when inventory quantity is over minimum quantity" do
    let(:minimum_quantity) { 50 }
    let(:current_quantity) { 100 }

    it "should return an empty array" do
      result = LowInventoryQuery.call(organization).map { |r| r.to_h.symbolize_keys }
      expect(result).to be_empty
    end
  end

  context "when minimum_quantity is equal to quantity" do
    let(:minimum_quantity) { 100 }
    let(:current_quantity) { 100 }

    it "should return an empty array" do
      result = LowInventoryQuery.call(organization).map { |r| r.to_h.symbolize_keys }
      expect(result).to be_empty
    end
  end

  context "when inventory quantity drops below minimum quantity" do
    let(:minimum_quantity) { 200 }
    let(:current_quantity) { 100 }

    it "should include the item in the low inventory list" do
      result = LowInventoryQuery.call(organization).map { |r| r.to_h.symbolize_keys }
      expect(result).to include({
        id: item.id,
        name: item.name,
        on_hand_minimum_quantity: 200,
        on_hand_recommended_quantity: 0,
        total_quantity: 100
      })
    end
  end

  context "when inventory quantity equals recommended quantity" do
    let(:minimum_quantity) { 50 }
    let(:recommended_quantity) { 100 }
    let(:current_quantity) { 100 }

    it "should return an empty array" do
      result = LowInventoryQuery.call(organization).map { |r| r.to_h.symbolize_keys }
      expect(result).to be_empty
    end
  end

  context "when inventory quantity drops below recommended quantity" do
    let(:minimum_quantity) { 50 }
    let(:recommended_quantity) { 200 }
    let(:current_quantity) { 75 }

    it "should include the item in the low inventory list" do
      result = LowInventoryQuery.call(organization).map { |r| r.to_h.symbolize_keys }
      expect(result).to include({
        id: item.id,
        name: item.name,
        on_hand_minimum_quantity: 50,
        on_hand_recommended_quantity: 200,
        total_quantity: 75
      })
    end
  end

  context "when items are in multiple storage locations" do
    let(:minimum_quantity) { 50 }
    let(:recommended_quantity) { 55 }
    let(:current_quantity) { 40 }
    let(:secondary_storage_location) { create :storage_location, organization: organization }

    it "should have no low inventory items when global total is above minimum" do
      TestInventory.create_inventory(organization, {secondary_storage_location.id => {item.id => 17}})
      result = LowInventoryQuery.call(organization).map { |r| r.to_h.symbolize_keys }
      expect(result).to be_empty
    end

    it "should have no low inventory items when global total is below minimum" do
      TestInventory.create_inventory(organization, {secondary_storage_location.id => {item.id => 2}})
      result = LowInventoryQuery.call(organization).map { |r| r.to_h.symbolize_keys }
      expect(result).to include({
        id: item.id,
        name: item.name,
        on_hand_minimum_quantity: 50,
        on_hand_recommended_quantity: 55,
        total_quantity: 42
      })
    end
  end
end
