require "rails_helper"

RSpec.describe HistoricalTrendService, type: :service do
  let(:organization) { create(:organization) }
  let(:type) { "Donation" }
  let(:service) { described_class.new(organization.id, type) }

  describe "#series" do
    let!(:item1) { create(:item, organization: organization, name: "Item 1") }
    let!(:item2) { create(:item, organization: organization, name: "Item 2") }
    let!(:line_item1) { create(:line_item, item: item1, itemizable_type: type, quantity: 10, created_at: 1.month.ago) }
    let!(:line_item2) { create(:line_item, item: item1, itemizable_type: type, quantity: 20, created_at: 2.months.ago) }
    let!(:line_item3) { create(:line_item, item: item2, itemizable_type: type, quantity: 30, created_at: 3.months.ago) }

    it "returns an array of items with their monthly data" do
      expected_result = [
        {name: "Item 1", data: [0, 0, 0, 0, 0, 0, 0, 0, 0, 20, 10, 0], visible: false},
        {name: "Item 2", data: [0, 0, 0, 0, 0, 0, 0, 0, 30, 0, 0, 0], visible: false}
      ]
      expect(service.series).to eq(expected_result)
    end
  end
end
