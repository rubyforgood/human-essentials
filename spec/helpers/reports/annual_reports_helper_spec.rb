RSpec.describe Reports::AnnualReportsHelper, type: :helper do
  describe "#available_date" do
    it "returns the first day of the following year when the current date is the first day of a given year" do
      travel_to Time.zone.local(2026, 0o1, 0o1)

      expect(helper.available_date).to eq("January 1, 2027")
    end

    it "returns the first day of the following year when the current date is the last day of a given year" do
      travel_to Time.zone.local(2026, 12, 31)

      expect(helper.available_date).to eq("January 1, 2027")
    end

    it "returns the first day of the following year" do
      travel_to Time.zone.local(2026, 0o4, 15)

      expect(helper.available_date).to eq("January 1, 2027")
    end
  end
end
