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

  describe "#date_range_label" do
    def labelled(name, range = nil)
      dummy_class.new(
        {filters: {date_range_label: name, date_range: range}.compact}, double("flash", now: {})
      )
    end

    # It reads as "13 distributions #{date_range_label}", so a branch that returns nothing
    # leaves the sentence ending in mid-air. One branch used to: a range starting today.
    it "never returns an empty phrase, for any preset" do
      travel_to Time.zone.local(2026, 3, 15) do
        helper = dummy_class.new({}, double("flash", now: {}))

        helper.date_range_presets.each do |name, (from, to)|
          range = "#{from.strftime("%B %d, %Y")} - #{to.strftime("%B %d, %Y")}"
          expect(labelled(name, range).date_range_label).to be_present, "#{name} produced nothing"
        end
      end
    end

    it "gives every preset a phrase of its own rather than describing it by its dates" do
      travel_to Time.zone.local(2026, 3, 15) do
        expect(labelled("Today").date_range_label).to eq("today")
        expect(labelled("Yesterday").date_range_label).to eq("yesterday")
        expect(labelled("Last 7 days").date_range_label).to eq("over the last 7 days")
        expect(labelled("Last 30 days").date_range_label).to eq("over the last 30 days")
        expect(labelled("This month").date_range_label).to eq("this month")
        expect(labelled("Last month").date_range_label).to eq("last month")
        expect(labelled("Last 12 months").date_range_label).to eq("over the last 12 months")
        expect(labelled("This year").date_range_label).to eq("this year")
        expect(labelled("Prior year").date_range_label).to eq("in the prior year")
        expect(labelled("All time").date_range_label).to eq("across all time")
      end
    end

    # "All time" is a hundred years wide. Formatted with :short -- "%d %b", no year -- it came
    # out as "during the period 19 Aug to 19 Aug", which reads as a single day.
    it "carries the year, so a wide range cannot read as one day" do
      described = labelled("Custom", "August 19, 1926 - August 19, 2027").date_range_label

      expect(described).to eq("from August 19, 1926 to August 19, 2027")
      expect(described).to include("1926").and include("2027")
    end

    it "describes a custom range by its ends, and a single day as one day" do
      travel_to Time.zone.local(2026, 3, 15) do
        expect(labelled("Custom", "March 3, 2026 - March 9, 2026").date_range_label)
          .to eq("from March 3, 2026 to March 9, 2026")
        expect(labelled("Custom", "March 3, 2026 - March 3, 2026").date_range_label)
          .to eq("on March 3, 2026")
        expect(labelled("Custom", "March 3, 2026 - March 15, 2026").date_range_label)
          .to eq("since March 3, 2026")
      end
    end

    # A range starting today returned "" -- "Showing 13 distributions."
    it "describes a range that starts today rather than returning nothing" do
      travel_to Time.zone.local(2026, 3, 15) do
        expect(labelled("Custom", "March 15, 2026 - December 1, 2026").date_range_label)
          .to eq("from March 15, 2026 to December 1, 2026")
      end
    end

    # It used to default to "this year" with no parameter, which described neither the default
    # window nor anything else the page was showing.
    it "describes the actual default window when no label was submitted" do
      travel_to Time.zone.local(2026, 3, 15) do
        helper = dummy_class.new({}, double("flash", now: {}))

        expect(helper.date_range_label).to eq("from January 15, 2026 to April 15, 2026")
        expect(helper.date_range_label).not_to eq("this year")
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

    # Guards the pairing between the two methods, exhaustively rather than by a hand-kept list.
    # Add a preset without a matching clause in #date_range_label and it silently falls through
    # to being described by its dates -- which is exactly how "This year" and "All time" came to
    # render as "during the period 01 Jan to 31 Dec".
    #
    # The default window is excluded on purpose: it has no name that reads as a phrase, and its
    # dates are the right way to describe it. Identified by its dates rather than by its label,
    # so renaming the option cannot silently drop it from this check. #date_range_label
    # downcases before matching, which is what lets the option labels read as sentence case.
    it "gives every preset but the default window a clause of its own" do
      helper = dummy_class.new({}, double("flash", now: {}))
      default_range = helper.selected_interval
      named = helper.date_range_presets.reject { |_name, range| range == default_range }.keys

      expect(named.size).to eq(10)

      named.each do |name|
        helper = dummy_class.new({filters: {date_range_label: name}}, double("flash", now: {}))

        expect(helper.date_range_label).not_to eq(helper.selected_range_described),
          "#{name.inspect} has no clause, so it is described by its dates"
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

    context "with an open-ended date range" do
      it "falls back to default date range and sets a flash notice" do
        open_ended_range = "August 25, 2025 - "
        flash_now = {}
        flash_double = double("flash", now: flash_now)
        helper = dummy_class.new({filters: {date_range: open_ended_range}}, flash_double)

        interval = helper.selected_interval
        default_start, default_end = helper.default_date.split(" - ").map { |d| Date.strptime(d, "%B %d, %Y") }

        expect(interval).to eq([default_start, default_end])
        expect(flash_now[:notice]).to eq("Invalid Date range provided. Reset to default date range")
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
