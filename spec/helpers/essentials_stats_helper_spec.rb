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

    describe "the caption" do
      it "is rendered above the card when given" do
        html = helper.essentials_stats([{label: "A", value: 1}], caption: "Over the last 30 days")

        expect(html).to include("Over the last 30 days")
        expect(html.index("Over the last 30 days")).to be < html.index("<dl")
      end

      # Uppercase is what this slot usually attracts; design.md has no exception for small text.
      it "is not upper-cased" do
        html = helper.essentials_stats([{label: "A", value: 1}], caption: "Over the last 30 days")

        expect(html).not_to include("uppercase")
      end

      it "is omitted entirely when blank" do
        expect(helper.essentials_stats([{label: "A", value: 1}])).to start_with("<div")
        expect(helper.essentials_stats([{label: "A", value: 1}], caption: "")).to start_with("<div")
      end
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
