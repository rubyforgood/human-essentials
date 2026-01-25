require "rails_helper"

RSpec.describe DateRangeHelper do
  let(:dummy_class) do
    Class.new do
      include DateRangeHelper

      attr_accessor :params, :flash

      def initialize(params = {}, flash = nil)
        @params = params
        @flash = flash
      end
    end
  end

  describe "#selected_interval" do
    context "with a valid date range" do
      it "parses the dates correctly" do
        valid_range = "February 21, 2025 - May 22, 2025"
        flash_double = double("flash", now: {})
        helper = dummy_class.new({filters: {date_range: valid_range}}, flash_double)

        interval = helper.selected_interval

        expect(interval).to eq([
          Date.new(2025, 2, 21),
          Date.new(2025, 5, 22)
        ])
        expect(helper.flash.now[:notice]).to be_nil
      end
    end

    context "with an invalid date range" do
      it "falls back to default date range and sets a flash notice" do
        invalid_range = "November 08 - February 08"
        flash_now = {}
        flash_double = double("flash", now: flash_now)
        helper = dummy_class.new({filters: {date_range: invalid_range}}, flash_double)

        interval = helper.selected_interval
        default_start, default_end = helper.default_date.split(" - ").map { |d| Date.strptime(d, "%B %d, %Y") }

        expect(interval).to eq([default_start, default_end])
        expect(flash_now[:notice]).to eq("Invalid Date range provided. Reset to default date range")
      end
    end
  end
end
