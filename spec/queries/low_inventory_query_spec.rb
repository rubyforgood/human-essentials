RSpec.describe LowInventoryQuery do
  subject { LowInventoryQuery.new(organization: organization).call }

  let(:organization) { create :organization }

  it { is_expected.to eq [] }

  context "with inventory items" do
    let(:storage_location) { create :storage_location, organization: organization }
    let(:minimum_quantity) { 0 }
    let(:recommended_quantity) { 0 }
    let!(:inventory_item) { create :inventory_item, item: item, storage_location: storage_location, quantity: 100 }

    let(:item) do
      create :item,
             organization: organization,
             on_hand_minimum_quantity: minimum_quantity,
             on_hand_recommended_quantity: recommended_quantity
    end

    it { is_expected.to eq [] }

    context "when minimum_quantity and recommended_quantity is nil" do
      let(:item) { create :item, organization: organization }

      it { is_expected.to eq [] }
    end

    context "when inventory quantity is over minimum quantity" do
      let(:minimum_quantity) { 50 }

      it { is_expected.to eq [] }
    end

    context "when minimum_quantity is equal to quantity" do
      let(:minimum_quantity) { 100 }

      it "returns the inventory item" do
        is_expected.to include inventory_item
      end
    end

    context "when inventory quantity drops below minimum quantity" do
      let(:minimum_quantity) { 200 }

      it "returns the inventory item" do
        is_expected.to include inventory_item
      end
    end

    context "when inventory quantity equals recommended quantity" do
      let(:recommended_quantity) { 100 }

      it "returns the inventory item" do
        is_expected.to include inventory_item
      end
    end

    context "when inventory quantity drops below recommended quantity" do
      let(:recommended_quantity) { 200 }

      it "returns the inventory item" do
        is_expected.to include inventory_item
      end
    end
  end
end