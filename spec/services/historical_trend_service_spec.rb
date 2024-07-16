RSpec.describe HistoricalTrendService, type: :service do
  let(:organization) { create(:organization) }
  let(:type) { "Donation" }
  let(:service) { described_class.new(organization.id, type) }

  describe "#series" do
    let!(:item1) { create(:item, organization: organization, name: "Item 1") }
    let!(:item2) { create(:item, organization: organization, name: "Item 2") }
    let!(:line_items) do
      (0..11).map do |n|
        create(:line_item, item: item1, itemizable_type: type, quantity: 10 * (n + 1), created_at: n.months.ago)
      end
    end
    let!(:line_item2) { create(:line_item, item: item2, itemizable_type: type, quantity: 60, created_at: 6.months.ago) }
    let!(:line_item3) { create(:line_item, item: item2, itemizable_type: type, quantity: 30, created_at: 3.months.ago) }

    it "returns an array of items with their monthly data" do
      expected_result = [
        {name: "Item 1", data: [120, 110, 100, 90, 80, 70, 60, 50, 40, 30, 20, 10], visible: false},
        {name: "Item 2", data: [0, 0, 0, 0, 0, 60, 0, 0, 30, 0, 0, 0], visible: false}
      ]
      expect(service.series).to eq(expected_result)
    end
  end
end
