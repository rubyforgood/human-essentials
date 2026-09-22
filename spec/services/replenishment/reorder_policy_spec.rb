RSpec.describe Replenishment::ReorderPolicy do
  let(:today) { Date.new(2026, 9, 1) }

  def decide(on_hand:, forecast: [304.0], sigma: 0.0, lead_time_days: 30.4, review_period_days: 30.4, service_level: 0.95)
    described_class.new(forecast:, sigma:, on_hand:, lead_time_days:, review_period_days:, service_level:, today:).call
  end

  describe ".z_score" do
    it "matches standard normal table values" do
      expect(described_class.z_score(0.5)).to be_within(1e-6).of(0)
      expect(described_class.z_score(0.95)).to be_within(1e-3).of(1.645)
      expect(described_class.z_score(0.99)).to be_within(1e-3).of(2.326)
      expect(described_class.z_score(0.01)).to be_within(1e-3).of(-2.326)
    end

    it "rejects impossible service levels" do
      expect { described_class.z_score(1.0) }.to raise_error(ArgumentError)
    end
  end

  context "with certain demand (sigma = 0)" do
    it "sets the reorder point to exactly lead-time demand" do
      decision = decide(on_hand: 1000)
      expect(decision.safety_stock).to eq(0)
      expect(decision.reorder_point).to eq(304)
      expect(decision.status).to eq(:ok)
      expect(decision.suggested_order).to eq(0)
      expect(decision.days_of_supply).to eq(100)
      expect(decision.stockout_date).to eq(today + 100)
    end
  end

  context "with uncertain demand" do
    it "adds z * sigma * sqrt(L) of safety stock" do
      decision = decide(on_hand: 1000, sigma: 100)
      expect(decision.safety_stock).to eq((1.645 * 100).ceil)
    end

    it "holds more safety stock for a higher service level" do
      low = decide(on_hand: 1000, sigma: 100, service_level: 0.90)
      high = decide(on_hand: 1000, sigma: 100, service_level: 0.99)
      expect(high.safety_stock).to be > low.safety_stock
    end
  end

  it "recommends ordering up to S when stock is at or below the reorder point" do
    decision = decide(on_hand: 250)
    # S = demand over L + R = 2 months = 608
    expect(decision.order_up_to).to eq(608)
    expect(decision.suggested_order).to eq(608 - 250)
  end

  it "flags items that will run out before a new order can arrive" do
    expect(decide(on_hand: 100).status).to eq(:critical)
    expect(decide(on_hand: 320, sigma: 50).status).to eq(:reorder)
  end

  it "respects a trend in the monthly forecast" do
    flat = decide(on_hand: 0, forecast: [304.0, 304.0], lead_time_days: 60.8)
    rising = decide(on_hand: 0, forecast: [304.0, 608.0], lead_time_days: 60.8)
    expect(rising.reorder_point).to be > flat.reorder_point
  end

  it "handles items with no demand" do
    decision = decide(on_hand: 50, forecast: [0.0])
    expect(decision.status).to eq(:no_demand)
    expect(decision.days_of_supply).to be_nil
  end
end
