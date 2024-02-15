load "lib/dispersed_past_dates_generator.rb"

RSpec.describe DispersedPastDatesGenerator do
  describe "constants" do
    it { expect(described_class::RANGES).to eq([0..6, 7..31, 32..300, 350..700]) }
  end

  describe "#next" do
    let(:number_of_dates_to_disperse) { 4 }
    let(:dates_generator) { described_class.new(number_of_dates_to_disperse) }

    it "returns equally dispersed dates between all time ranges" do
      expect(dates_generator.next).to be_between(Time.zone.today - 6.days, Time.zone.today)
      expect(dates_generator.next).to be_between(Time.zone.today - 31.days, Time.zone.today - 7.days)
      expect(dates_generator.next).to be_between(Time.zone.today - 300.days, Time.zone.today - 32.days)
      expect(dates_generator.next).to be_between(Time.zone.today - 700.days, Time.zone.today - 350.days)
    end

    context "when number of dates is higher than number time ranges" do
      let(:number_of_dates_to_disperse) { 8 }

      it "fits few dates in one time period" do
        expect(dates_generator.next).to be_between(Time.zone.today - 6.days, Time.zone.today)
        expect(dates_generator.next).to be_between(Time.zone.today - 6.days, Time.zone.today)
        expect(dates_generator.next).to be_between(Time.zone.today - 31.days, Time.zone.today - 7.days)
        expect(dates_generator.next).to be_between(Time.zone.today - 31.days, Time.zone.today - 7.days)
        expect(dates_generator.next).to be_between(Time.zone.today - 300.days, Time.zone.today - 32.days)
        expect(dates_generator.next).to be_between(Time.zone.today - 300.days, Time.zone.today - 32.days)
        expect(dates_generator.next).to be_between(Time.zone.today - 700.days, Time.zone.today - 350.days)
        expect(dates_generator.next).to be_between(Time.zone.today - 700.days, Time.zone.today - 350.days)
      end
    end

    context "when #next is called more times than declared number of dates" do
      it "starts cycle from beginning" do
        expect(dates_generator.next).to be_between(Time.zone.today - 6.days, Time.zone.today)
        expect(dates_generator.next).to be_between(Time.zone.today - 31.days, Time.zone.today - 7.days)
        expect(dates_generator.next).to be_between(Time.zone.today - 300.days, Time.zone.today - 32.days)
        expect(dates_generator.next).to be_between(Time.zone.today - 700.days, Time.zone.today - 350.days)
        expect(dates_generator.next).to be_between(Time.zone.today - 6.days, Time.zone.today)
      end
    end
  end
end
