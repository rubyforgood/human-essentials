RSpec.describe Reports::AnnualReportsHelper, type: :helper do
  describe "#available_date" do
    it "returns the first day of the following year with a custom date format" do
      travel_to Time.zone.local(2026, 0o1, 0o1)

      expect(helper.available_date).to eq("January 1, 2027")
    end
  end
end
