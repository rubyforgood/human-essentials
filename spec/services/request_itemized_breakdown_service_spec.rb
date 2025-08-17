RSpec.describe RequestItemizedBreakdownService, type: :service do
  let(:organization) { create(:organization) }

  let(:item_a) { create(:item, organization: organization, name: "A Diapers", on_hand_minimum_quantity: 4) }
  let(:item_b) { create(:item, organization: organization, name: "B Diapers", on_hand_minimum_quantity: 8) }

  let(:request_1) { create(:request, organization: organization) }
  let(:request_2) { create(:request, organization: organization) }

  let(:storage_location) { create(:storage_location, organization: organization) }

  before do
    TestInventory.create_inventory(organization, {
      storage_location.id => {
        item_a.id => 3,
        item_b.id => 20
      }
    })

    create(:item_request, request: request_1, partner_request_id: request_1.id, item: item_a, quantity: 5, request_unit: nil)
    create(:item_request, request: request_2, partner_request_id: request_2.id, item: item_b, quantity: 10, request_unit: nil)
  end

  describe "#fetch" do
    subject(:result) do
      described_class.call(organization: organization, request_ids: [request_1.id, request_2.id])
    end

    it "should include the break down of requested items" do
      expected_output = [
        {name: "A Diapers", item_id: item_a.id, unit: nil, quantity: 5, on_hand: 3, onhand_minimum: 4, below_onhand_minimum: true},
        {name: "B Diapers", item_id: item_b.id, unit: nil, quantity: 10, on_hand: 20, onhand_minimum: 8, below_onhand_minimum: false}
      ]
      expect(result).to eq(expected_output)
    end
  end

  describe "#fetch_csv" do
    subject(:subject) do
      described_class.call(organization: organization, request_ids: [request_1.id, request_2.id], format: :csv)
    end

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
