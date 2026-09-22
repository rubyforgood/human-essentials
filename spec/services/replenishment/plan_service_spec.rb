RSpec.describe Replenishment::PlanService do
  let(:organization) { create(:organization) }
  let(:storage_location) { create(:storage_location, organization:) }
  let(:partner) { create(:partner, organization:) }
  let(:diapers) { create(:item, organization:, name: "Size 4 Diapers") }
  let(:wipes) { create(:item, organization:, name: "Wipes") }
  let(:today) { Date.new(2026, 9, 15) }

  def distribute(item, quantity, issued_at)
    distribution = create(:distribution, organization:, storage_location:, partner:, issued_at:)
    distribution.line_items.create!(item:, quantity:)
  end

  before do
    # 12 complete months of steady diaper demand, plus a partial current month
    12.times { |i| distribute(diapers, 1000, today.beginning_of_month.months_ago(i + 1) + 3.days) }
    distribute(diapers, 50, today.beginning_of_month + 1.day)
    distribute(wipes, 30, today.beginning_of_month.months_ago(2))
    TestInventory.create_inventory(organization, {storage_location.id => {diapers.id => 400, wipes.id => 5000}})
  end

  describe Replenishment::DemandHistory do
    it "buckets distributions by complete month and skips the current month" do
      history = described_class.new(organization, months: 12, today:)
      series = history.series_by_item
      expect(series[diapers.id]).to eq(Array.new(12, 1000))
      expect(series[wipes.id][10]).to eq(30)
      expect(history.last_month).to eq(Date.new(2026, 8, 1))
    end

    it "can use partner requests as the demand signal" do
      create(:request, organization:, partner:, created_at: today.beginning_of_month.months_ago(1),
        request_items: [{"item_id" => diapers.id, "quantity" => 1500}])
      series = described_class.new(organization, months: 12, source: :requests, today:).series_by_item
      expect(series[diapers.id].last).to eq(1500)
    end
  end

  it "flags a fast-moving, low-stock item for immediate reorder" do
    rows = described_class.new(organization, today:).rows
    row = rows.find { |r| r.item == diapers }
    expect(row.on_hand).to eq(400)
    expect(row.forecast.next_month).to be_within(1).of(1000)
    expect(row.decision.status).to eq(:critical)
    expect(row.decision.suggested_order).to be > 0
    expect(rows.first.item).to eq(diapers) # most urgent first
  end

  it "leaves a well-stocked item alone" do
    row = described_class.new(organization, today:).rows.find { |r| r.item == wipes }
    expect(row.decision.suggested_order).to eq(0)
  end

  it "summarizes item counts by status" do
    summary = described_class.new(organization, today:).summary
    expect(summary[:critical]).to eq(1)
    expect(summary[:items]).to eq(2)
  end
end
