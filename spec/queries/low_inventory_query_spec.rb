RSpec.describe LowInventoryQuery do
  subject { LowInventoryQuery.call(organization).map { |r| r.to_h.symbolize_keys } }

  let(:organization) { create :organization }
  let(:storage_location) { create :storage_location, organization: organization }

  let(:minimum_quantity) { 0 }
  let(:recommended_quantity) { 0 }
  let(:inventory_item_quantity) { 100 }

  let(:item) do
    create :item,
      organization: organization,
      on_hand_minimum_quantity: minimum_quantity,
      on_hand_recommended_quantity: recommended_quantity
  end

  let!(:purchase) {
    create :purchase,
      :with_items,
      organization: organization,
      storage_location: storage_location,
      item: item,
      item_quantity: inventory_item_quantity,
      issued_at: Time.current
  }

  context "when minimum_quantity and recommended_quantity is nil" do
    let(:item) { create :item, organization: organization }

    it { is_expected.to eq [] }
  end

  context "when minimum_quantity is 0 and recommended_quantity is nil and item quantity is 0" do
    let(:item) { create :item, organization: organization }
    let(:minimum_quantity) { 0 }
    let(:inventory_item_quantity) { 0 }

    it { is_expected.to eq [] }
  end

  context "when inventory quantity is over minimum quantity" do
    let(:minimum_quantity) { 50 }

    it { is_expected.to eq [] }
  end

  context "when minimum_quantity is equal to quantity" do
    let(:minimum_quantity) { 100 }

    it { is_expected.to eq [] }
  end

  context "when inventory quantity drops below minimum quantity" do
    let(:minimum_quantity) { 200 }

    it {
      is_expected.to include({
        id: item.id,
        name: item.name,
        on_hand_minimum_quantity: 200,
        on_hand_recommended_quantity: 0,
        total_quantity: 100
      })
    }
  end

  context "when inventory quantity equals recommended quantity" do
    let(:recommended_quantity) { 100 }

    it { is_expected.to eq [] }
  end

  context "when inventory quantity drops below recommended quantity" do
    let(:recommended_quantity) { 200 }

    it {
      is_expected.to include({
        id: item.id,
        name: item.name,
        on_hand_minimum_quantity: 0,
        on_hand_recommended_quantity: 200,
        total_quantity: 100
      })
    }
  end
end
