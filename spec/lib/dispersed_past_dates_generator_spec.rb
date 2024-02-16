load "lib/dispersed_past_dates_generator.rb"

RSpec.describe DispersedPastDatesGenerator do
  describe "constants" do
    it "has 4 day ranges for generation of past dates" do
      expect(described_class::DAYS_RANGES).to eq([0..6, 7..30, 31..300, 350..700])
    end
  end

  describe "#next" do
    let(:dates_generator) { described_class.new }

    it "returns equally dispersed dates between all time ranges" do
      expect(dates_generator.next).to be_between(Time.zone.today - 6.days, Time.zone.today)
      expect(dates_generator.next).to be_between(Time.zone.today - 30.days, Time.zone.today - 7.days)
      expect(dates_generator.next).to be_between(Time.zone.today - 300.days, Time.zone.today - 31.days)
      expect(dates_generator.next).to be_between(Time.zone.today - 700.days, Time.zone.today - 350.days)
      expect(dates_generator.next).to be_between(Time.zone.today - 6.days, Time.zone.today)
      expect(dates_generator.next).to be_between(Time.zone.today - 30.days, Time.zone.today - 7.days)
      expect(dates_generator.next).to be_between(Time.zone.today - 300.days, Time.zone.today - 31.days)
      expect(dates_generator.next).to be_between(Time.zone.today - 700.days, Time.zone.today - 350.days)
    end
  end
end
