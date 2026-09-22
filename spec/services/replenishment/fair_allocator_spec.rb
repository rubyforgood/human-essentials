RSpec.describe Replenishment::FairAllocator do
  def plan(supply, requests, policy, weights: {})
    described_class.new(supply:, requests:, weights:).call(policy)
  end

  it "fills every request when there is enough supply" do
    result = plan(1000, {a: 100, b: 200}, :max_min)
    expect(result.allocations).to eq(a: 100, b: 200)
    expect(result.min_fill_rate).to eq(1.0)
  end

  describe "proportional" do
    it "gives every partner the same share of its request" do
      result = plan(500, {a: 100, b: 900}, :proportional)
      expect(result.allocations).to eq(a: 50, b: 450)
      expect(result.jain_index).to be_within(1e-9).of(1.0)
    end
  end

  describe "max-min (water-filling)" do
    it "fully covers small requests and splits the rest evenly" do
      result = plan(500, {a: 100, b: 900, c: 900}, :max_min)
      expect(result.allocations).to eq(a: 100, b: 200, c: 200)
    end

    it "lets weights tilt the split" do
      result = plan(300, {a: 1000, b: 1000}, :max_min, weights: {a: 2, b: 1})
      expect(result.allocations).to eq(a: 200, b: 100)
    end

    it "gives the smallest partner at least as much as proportional does" do
      requests = {a: 40, b: 700, c: 1260}
      mm = plan(600, requests, :max_min)
      prop = plan(600, requests, :proportional)
      expect(mm.allocations[:a]).to be >= prop.allocations[:a]
    end
  end

  it "always hands out whole units, never exceeding supply or any request" do
    rng = Random.new(7)
    50.times do
      requests = (1..rng.rand(2..8)).to_h { |i| [i, rng.rand(1..500)] }
      supply = rng.rand(0..requests.values.sum)
      %i[proportional max_min].each do |policy|
        result = plan(supply, requests, policy)
        expect(result.allocated).to eq(supply)
        result.allocations.each { |k, v| expect(v).to be_between(0, requests[k]) }
      end
    end
  end

  it "ignores zero-quantity requests" do
    result = plan(10, {a: 0, b: 20}, :max_min)
    expect(result.allocations).to eq(b: 10)
  end
end
