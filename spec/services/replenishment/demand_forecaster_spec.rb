RSpec.describe Replenishment::DemandForecaster do
  def forecast(series, horizon: 3)
    described_class.new(series, horizon:).call
  end

  it "returns zeros when there is no demand" do
    result = forecast([0, 0, 0, 0, 0, 0])
    expect(result.model).to eq("none")
    expect(result.forecast).to eq([0.0, 0.0, 0.0])
  end

  it "falls back to an average for very short histories" do
    result = forecast([100, 120, 110])
    expect(result.model).to eq("average")
    expect(result.next_month).to be_within(0.1).of(110)
    expect(result.sigma).to be > 0
  end

  it "forecasts a flat series as flat, with (near) zero error" do
    result = forecast(Array.new(12, 500))
    expect(result.forecast).to all(be_within(1).of(500))
    expect(result.sigma).to be < 1
  end

  it "follows a steady upward trend" do
    series = (1..18).map { |i| 100 + (20 * i) }
    result = forecast(series)
    expect(result.model).to eq("holt")
    expect(result.next_month).to be > series.last
    expect(result.forecast).to eq(result.forecast.sort) # non-decreasing
  end

  it "beats the naive forecast on a noisy but stable series" do
    rng = Random.new(42)
    series = Array.new(24) { 1000 + rng.rand(-200..200) }
    result = forecast(series)
    expect(result.skill).to be > 0
    expect(result.next_month).to be_within(150).of(1000)
  end

  it "uses last year's pattern for strongly seasonal data" do
    season = [100, 100, 100, 100, 100, 900, 900, 100, 100, 100, 100, 100]
    result = forecast(season * 3)
    expect(result.model).to eq("seasonal_naive")
  end

  it "never forecasts negative demand" do
    series = [900, 800, 600, 400, 250, 100, 20, 0, 0]
    expect(forecast(series).forecast).to all(be >= 0)
  end
end
