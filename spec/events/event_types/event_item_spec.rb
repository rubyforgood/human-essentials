RSpec.describe EventTypes::EventItem do
  let(:quantity) { 70 }
  let(:reserved_quantity) { 30 }
  subject(:base_item) { described_class.new(item_id: 1, **{ quantity: quantity, reserved_quantity: reserved_quantity }.compact_blank) }

  describe "#physical_quantity" do
    subject { base_item.physical_quantity }

    it "sums available and reserved" do
      expect(subject).to eq(quantity + reserved_quantity)
    end
  end

  describe "#reserved_quantity" do    
    subject { base_item.reserved_quantity }

    context "when no reserve quantity is provided" do
      let(:reserved_quantity) { nil }

      it "defaults to zero so payloads predating the attribute still load" do
        expect(subject).to eq(0)
        expect(base_item.physical_quantity).to eq(70)
      end
    end
  end
end
