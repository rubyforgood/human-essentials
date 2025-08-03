RSpec.describe RequestItemizedBreakdownService, type: :service do
  let(:organization) { create(:organization) }

  let(:item_a) do
    create(:item, organization: organization, on_hand_minimum_quantity: 4, name: "A Diapers")
  end
  let(:item_b) do
    create(:item, organization: organization, on_hand_minimum_quantity: 8, name: "B Diapers")
  end

  let(:request_1) do
    create(:request, organization: organization, request_items: [
      {"item_id" => item_a.id, "quantity" => 5}
    ])
  end

  let(:request_2) do
    create(:request, organization: organization, request_items: [
      {"item_id" => item_b.id, "quantity" => 10}
    ])
  end

  let(:expected_output) do
    [
      {name: item_a.name, item_id: item_a.id, unit: nil, quantity: 5, on_hand: 3, onhand_minimum: 4, below_onhand_minimum: true},
      {name: item_b.name, item_id: item_b.id, unit: nil, quantity: 10, on_hand: 20, onhand_minimum: 8, below_onhand_minimum: false}
    ]
  end

  before do
    allow_any_instance_of(View::Inventory).to receive(:quantity_for).with(item_id: item_a.id).and_return(3)
    allow_any_instance_of(View::Inventory).to receive(:quantity_for).with(item_id: item_b.id).and_return(20)
    allow_any_instance_of(View::Inventory).to receive(:all_items).and_return([
      OpenStruct.new(id: item_a.id, quantity: 3, on_hand_minimum_quantity: 4),
      OpenStruct.new(id: item_b.id, quantity: 20, on_hand_minimum_quantity: 8)
    ])
  end

  describe "#fetch" do
    subject { service.fetch }
    let(:service) { described_class.new(organization: organization, request_ids: [request_1.id, request_2.id]) }

    it "should include the break down of requested items" do
      expect(subject).to eq(expected_output)
    end
  end

  describe "#fetch_csv" do
    subject { service.fetch_csv }
    let(:service) { described_class.new(organization: organization, request_ids: [request_1.id, request_2.id]) }

    it "should output the expected output but in CSV format" do
      expected_csv = <<~CSV
        Item,Total Requested,Total On Hand
        A Diapers,5,3
        B Diapers,10,20
      CSV

      expect(subject).to eq(expected_csv)
    end
  end
end
