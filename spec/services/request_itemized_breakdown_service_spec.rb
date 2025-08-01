RSpec.describe RequestItemizedBreakdownService, type: :service do
  let(:organization) { create(:organization) }

  let(:item_a) { create(:item, organization: organization, name: "A Diapers") }
  let(:item_b) { create(:item, organization: organization, name: "B Diapers") }

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
      {name: item_a.name, item_id: item_a.id, unit: nil, quantity: 5, on_hand: 3, below_requested: true},
      {name: item_b.name, item_id: item_b.id, unit: nil, quantity: 10, on_hand: 20, below_requested: false}
    ]
  end

  before do
    allow_any_instance_of(View::Inventory).to receive(:quantity_for).with(item_id: item_a.id).and_return(3)
    allow_any_instance_of(View::Inventory).to receive(:quantity_for).with(item_id: item_b.id).and_return(20)
  end

  describe "#fetch" do
    subject { service.fetch }
    let(:service) { described_class.new(organization: organization, request_ids: [request_1.id, request_2.id]) }

    it "should include the break down of requested items" do
      expect(subject).to match_array(expected_output)
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
