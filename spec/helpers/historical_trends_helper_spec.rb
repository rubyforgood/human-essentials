require "rspec"

RSpec.describe HistoricalTrendsHelper do
  describe "#last_12_months" do
    it "returns the last 12 months starting from July when the current month is June" do
      allow_any_instance_of(Time).to receive(:month).and_return(6)

      expect(last_12_months).to eq(["Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar", "Apr", "May", "Jun"])
    end

    it "returns the last 12 months starting from Feb when the current month is Jan" do
      allow_any_instance_of(Time).to receive(:month).and_return(1)

      expect(last_12_months).to eq(["Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan"])
    end

    it "returns the last 12 months starting from Jan when the current month is Dec" do
      allow_any_instance_of(Time).to receive(:month).and_return(12)

      expect(last_12_months).to eq(["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"])
    end
  end
end
