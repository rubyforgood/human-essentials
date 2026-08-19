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

  describe "#date_range_presets" do
    # The point of computing these server-side is that they agree with the Time.zone the query
    # is filtered in. Litepicker built them from the browser's clock, which could be a day out.
    it "computes each range in Time.zone" do
      travel_to Time.zone.local(2026, 3, 15) do
        presets = dummy_class.new.date_range_presets

        expect(presets["Today"]).to eq([Date.new(2026, 3, 15), Date.new(2026, 3, 15)])
        expect(presets["Yesterday"]).to eq([Date.new(2026, 3, 14), Date.new(2026, 3, 14)])
        expect(presets["Last 7 days"]).to eq([Date.new(2026, 3, 9), Date.new(2026, 3, 15)])
        expect(presets["Last 30 days"]).to eq([Date.new(2026, 2, 14), Date.new(2026, 3, 15)])
        expect(presets["This month"]).to eq([Date.new(2026, 3, 1), Date.new(2026, 3, 31)])
        expect(presets["Last month"]).to eq([Date.new(2026, 2, 1), Date.new(2026, 2, 28)])
        expect(presets["This year"]).to eq([Date.new(2026, 1, 1), Date.new(2026, 12, 31)])
        expect(presets["Prior year"]).to eq([Date.new(2025, 1, 1), Date.new(2025, 12, 31)])
      end
    end

    # If these two ever drift, every page opens on "Custom" with no preset selected.
    it "includes the default range, so a page that has not been filtered matches a preset" do
      travel_to Time.zone.local(2026, 3, 15) do
        helper = dummy_class.new({}, double("flash", now: {}))

        expect(helper.date_range_presets.values).to include(helper.selected_interval)
      end
    end

    # #date_range_label downcases before matching, which is what lets the option labels read as
    # sentence case while the prose it produces keeps working.
    it "names presets that #date_range_label still recognises" do
      presets = dummy_class.new.date_range_presets

      ["Today", "Yesterday", "Last 7 days", "Last 30 days", "This month", "Last month",
        "Last 12 months", "Prior year"].each do |name|
        expect(presets).to have_key(name)

        helper = dummy_class.new({filters: {date_range_label: name}}, double("flash", now: {}))
        expect(helper.date_range_label).not_to eq(helper.selected_range_described)
      end
    end
  end

  describe "#selected_date_range_preset" do
    it "names the preset whose dates match the selection" do
      travel_to Time.zone.local(2026, 3, 15) do
        helper = dummy_class.new(
          {filters: {date_range: "March 15, 2026 - March 15, 2026"}}, double("flash", now: {})
        )

        expect(helper.selected_date_range_preset).to eq("Today")
      end
    end

    # Matched on the dates, not on filters[date_range_label] -- a stale or hand-edited label
    # must not select an option that does not describe the range being shown.
    it "ignores the label parameter when the dates disagree with it" do
      travel_to Time.zone.local(2026, 3, 15) do
        helper = dummy_class.new(
          {filters: {date_range: "March 15, 2026 - March 15, 2026", date_range_label: "All time"}},
          double("flash", now: {})
        )

        expect(helper.selected_date_range_preset).to eq("Today")
      end
    end

    it "is nil for a range that matches no preset, so the filter reads as custom" do
      travel_to Time.zone.local(2026, 3, 15) do
        helper = dummy_class.new(
          {filters: {date_range: "March 3, 2026 - March 9, 2026"}}, double("flash", now: {})
        )

        expect(helper.selected_date_range_preset).to be_nil
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
