require "rspec"

RSpec.describe HistoricalTrendsHelper do
  describe "#last_12_months" do
    it "returns the last 12 months starting from July 2023 when the current month is June 2024" do
      allow_any_instance_of(Time).to receive(:month).and_return(6)
      allow_any_instance_of(Time).to receive(:year).and_return(2024)

      expect(last_12_months).to eq(["Jul 2023", "Aug 2023", "Sep 2023", "Oct 2023", "Nov 2023", "Dec 2023", "Jan 2024", "Feb 2024", "Mar 2024", "Apr 2024", "May 2024", "Jun 2024"])
    end

    it "returns the last 12 months starting from Feb 1999 when the current month is Jan 2000" do
      allow_any_instance_of(Time).to receive(:month).and_return(1)
      allow_any_instance_of(Time).to receive(:year).and_return(2000)

      expect(last_12_months).to eq(["Feb 1999", "Mar 1999", "Apr 1999", "May 1999", "Jun 1999", "Jul 1999", "Aug 1999", "Sep 1999", "Oct 1999", "Nov 1999", "Dec 1999", "Jan 2000"])
    end

    it "returns the last 12 months starting from Jan 2010 when the current month is Dec 2010" do
      allow_any_instance_of(Time).to receive(:month).and_return(12)
      allow_any_instance_of(Time).to receive(:year).and_return(2010)

      expect(last_12_months).to eq(["Jan 2010", "Feb 2010", "Mar 2010", "Apr 2010", "May 2010", "Jun 2010", "Jul 2010", "Aug 2010", "Sep 2010", "Oct 2010", "Nov 2010", "Dec 2010"])
    end
  end
end
