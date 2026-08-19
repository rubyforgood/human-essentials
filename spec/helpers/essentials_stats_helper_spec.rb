require "rails_helper"

RSpec.describe EssentialsUiHelper, type: :helper do
  describe "#essentials_stats" do
    # A block given to `tag` renders nothing for a non-String, so an Integer value produced an
    # empty figure while every currency stat, already a String, looked fine.
    it "renders a numeric value" do
      html = helper.essentials_stats([{label: "Total items", value: 35_065}])
      expect(html).to include("35065")
    end

    it "renders a string value" do
      html = helper.essentials_stats([{label: "Spent", value: "$1,311.22"}])
      expect(html).to include("$1,311.22")
    end

    it "keeps the spec hook class the request specs match on" do
      html = helper.essentials_stats([{label: "Items", value: 12, value_class: "total_distributed"}])
      expect(html).to include('<span class="total_distributed">12</span>')
    end

    it "pairs each label with its value as a description list" do
      html = helper.essentials_stats([{label: "Total items", value: 3}])
      expect(html).to include("<dl")
      expect(html).to include("<dt")
      expect(html).to include("<dd")
      expect(html).not_to include("<h2")
    end

    it "puts the figures in one card rather than a filled box each" do
      html = helper.essentials_stats([{label: "A", value: 1}, {label: "B", value: 2}])

      expect(html).to include("rounded-2xl border border-slate-200 bg-white shadow-sm")
      expect(html).to include("gap-px bg-slate-200")
      expect(html).not_to include("bg-slate-50")
      expect(html).not_to include("rounded-xl")
    end

    describe "the header" do
      it "puts the title and subtitle inside the card, above the figures" do
        html = helper.essentials_stats([{label: "A", value: 1}],
          title: "Totals", subtitle: "13 donations, today")

        expect(html).to include("<h2").and include("Totals").and include("13 donations, today")
        expect(html.index("Totals")).to be < html.index("<dl")
        expect(html.index("13 donations, today")).to be < html.index("<dl")
      end

      # Uppercase is what this slot usually attracts; design.md has no exception for small text.
      it "is not upper-cased" do
        html = helper.essentials_stats([{label: "A", value: 1}],
          title: "Totals", subtitle: "Over the last 30 days")

        expect(html).not_to include("uppercase")
      end

      it "is omitted entirely when no title is given" do
        html = helper.essentials_stats([{label: "A", value: 1}])

        expect(html).to start_with("<div")
        expect(html).not_to include("<h2")
      end
    end
  end

  describe "#essentials_stats_scope" do
    def scope(count, noun, params = {})
      allow(helper).to receive(:params).and_return(ActionController::Parameters.new(params))
      helper.essentials_stats_scope(count, noun)
    end

    before { allow(helper).to receive(:date_range_label).and_return("today") }

    it "counts and names what the figures cover" do
      expect(scope(13, "donation")).to eq("13 donations, today")
    end

    it "reads properly at one and at none" do
      expect(scope(1, "donation")).to eq("1 donation, today")
      expect(scope(0, "donation")).to eq("No donations, today")
    end

    it "delimits a large count" do
      expect(scope(106_644, "item")).to eq("106,644 items, today")
    end

    it "says so when something other than the dates is being filtered" do
      expect(scope(4, "donation", filters: {by_source: "Manufacturer"}))
        .to eq("4 donations matching these filters, today")
    end

    # A date range is always set, so counting it would make every page claim to be filtered
    # when the user has touched nothing.
    it "does not count the date range as a filter" do
      params = {filters: {date_range: "March 3, 2026 - March 9, 2026", date_range_label: "Custom"}}

      expect(scope(13, "donation", params)).to eq("13 donations, today")
    end

    it "ignores a filter that is present but blank" do
      expect(scope(13, "donation", filters: {by_source: ""})).to eq("13 donations, today")
    end
  end

  # The band used to be a flat `sm:grid-cols-2 lg:grid-cols-3` whatever the number of figures, so
  # it orphaned a tile on every page that had one. With the separators drawn by a backdrop showing
  # through 1px gaps, an empty cell is not whitespace -- it is a grey block.
  describe "EssentialsUiHelper::STATS_COLUMNS" do
    it "divides exactly, at every breakpoint it names, for every count it maps" do
      EssentialsUiHelper::STATS_COLUMNS.each do |count, classes|
        columns = classes.scan(/grid-cols-(\d+)/).flatten.map(&:to_i)

        columns.each do |n|
          expect(count % n).to eq(0),
            "#{count} figures in #{n} columns leaves #{count % n} cell(s) of empty backdrop"
        end
      end
    end

    it "covers every count the app actually renders" do
      counts = Dir["app/views/**/*.erb"].flat_map { |f|
        File.read(f).scan(/essentials_stats\(\[(.*?)\]\s*[,)]/m).flatten.map { |a| a.scan("{label:").size }
      }.uniq

      expect(counts).not_to be_empty
      expect(counts).to all(satisfy { |n| EssentialsUiHelper::STATS_COLUMNS.key?(n) })
    end
  end
end
