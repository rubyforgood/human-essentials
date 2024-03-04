RSpec.describe DistributionItemizedBreakdownService, type: :service do
  let(:organization) { create(:organization) }
  let(:distribution_ids) { [distribution_1, distribution_2, distribution_3].map(&:id) }
  let(:item_a) do
    create(:item, organization: organization, on_hand_minimum_quantity: 9999, name: "A Diapers")
  end
  let(:item_b) do
    create(:item, organization: organization, on_hand_minimum_quantity: 5, name: "B Diapers")
  end
  let(:distribution_1) { create(:distribution, :with_items, item: item_a, item_quantity: 500, organization: organization) }
  let(:distribution_2) { create(:distribution, :with_items, item: item_b, item_quantity: 100, organization: organization) }
  let(:distribution_3) { create(:distribution, :with_items, item: item_b, item_quantity: 100, organization: organization) }
  let(:expected_output) do
    [
      {name: item_a.name, distributed: 500, current_onhand: 100, onhand_minimum: item_a.on_hand_minimum_quantity, below_onhand_minimum: true},
      {name: item_b.name, distributed: 200, current_onhand: 200, onhand_minimum: item_b.on_hand_minimum_quantity, below_onhand_minimum: false}
    ]
  end

  let(:distribution_ids) { [distribution_1, distribution_2, distribution_3].map(&:id) }

  describe "#fetch" do
    subject { service.fetch }
    let(:service) { described_class.new(organization: organization, distribution_ids: distribution_ids) }

    it "should include the break down of items distributed with onhand data" do
      expect(subject).to eq(expected_output)
    end
  end

  describe "#fetch_csv" do
    subject { service.fetch_csv }
    let(:service) { described_class.new(organization: organization, distribution_ids: distribution_ids) }

    it "should output the expected output but in CSV format" do
      expected_output_csv = <<~CSV
        Item,Total Distribution,Total On Hand
        A Diapers,500,100
        B Diapers,200,200
      CSV

      expect(subject).to eq(expected_output_csv)
    end
  end
end
