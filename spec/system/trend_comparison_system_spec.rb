# The two other parameters on a trend page: the previous period, and the item category.
# See design.md -- "A chart answers one question".
#
# Both were chosen over alternatives that read better in a mockup than they hold up in use. The
# comparison is the window shifted back by *its own length*, not "the same months last year", which
# is wrong for any window that is not a whole year. The breakdown is by item *category* rather than
# a top-8-and-Other cut, because a category is a grouping the bank already maintains and "Other"
# would have been a quarter of everything.
RSpec.describe "Trend comparison and categories", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:storage_location) { create(:storage_location, organization: organization) }
  let!(:nappies) { create(:item_category, organization: organization, name: "Nappies") }
  let!(:period) { create(:item_category, organization: organization, name: "Period products") }
  let!(:in_nappies) { create(:item, organization: organization, name: "Kids (Size 2)", item_category: nappies) }
  let!(:in_period) { create(:item, organization: organization, name: "Tampons", item_category: period) }
  let!(:uncategorised) { create(:item, organization: organization, name: "Wipes", item_category: nil) }

  before do
    TestInventory.create_inventory(organization,
      storage_location.id => {in_nappies.id => 9000, in_period.id => 9000, uncategorised.id => 9000})
    # Something in this window and something in the one before it, so the comparison has both ends.
    [in_nappies, in_period, uncategorised].each do |item|
      [1, 14].each do |months_ago|
        create(:distribution, :with_items, item: item, organization: organization,
          storage_location: storage_location, issued_at: months_ago.months.ago)
      end
    end
    sign_in user
  end

  def chart
    expect(page).to have_css("svg.highcharts-root")
    page.evaluate_script(<<~JS)
      (() => {
        const el = document.querySelector("[data-controller~='highchart']");
        const c = window.Stimulus.getControllerForElementAndIdentifier(el, "highchart");
        if (!c || !c.chart) return null;
        return {
          names: c.chart.series.map((s) => s.name),
          types: c.chart.series.map((s) => s.type),
          stacked: !!(c.chart.series[0] && c.chart.series[0].options.stacking)
        };
      })()
    JS
  end

  describe "the filter bar" do
    it "keeps both filters on the line rather than folding them behind a button" do
      # The bar folds everything past two controls, and that limit is measured: two plus the gap is
      # about 530px, and three do not fit at the narrowest width the table stays a table. A third
      # control here would have hidden the month range -- the control the page was just given.
      visit historical_trends_distributions_path

      expect(page).to have_css("#filters_months_trigger", visible: true)
      expect(page).to have_css("#filters_compare_trigger", visible: true)
      expect(page).to have_no_button("Filters")
    end
  end

  describe "with nothing chosen" do
    it "draws one total and does not stack" do
      # It used to stack one band per category. That is a series count taken from the data, and
      # nothing in the app bounds the number of categories -- see "A chart's series count is a
      # constant" in design.md. The breakdown is the table, and the reader chooses what to compare.
      visit historical_trends_distributions_path

      expect(chart["stacked"]).to be(false)
      expect(chart["names"]).to eq(["All items"])
    end
  end

  describe "narrowed to one category" do
    it "draws that category alone, and lists only its items" do
      visit historical_trends_distributions_path
      compare_with "Period products"

      expect(page).to have_css("h2", text: "Total per month")
      expect(page).to have_content("Tampons")
      expect(page).to have_no_content("Kids (Size 2)")
      expect(chart["stacked"]).to be(false)
      expect(chart["names"]).to eq(["Period products"])
    end

    it "can be narrowed to a single item, not just a category" do
      # Two kinds in one list: somebody thinking "how are wipes doing" should not have to know
      # first whether wipes is a category or an item.
      visit historical_trends_distributions_path
      compare_with "Wipes"

      expect(page).to have_content("Wipes")
      expect(page).to have_no_content("Tampons")
    end
  end

  describe "comparing with the previous period" do
    before do
      visit historical_trends_distributions_path
      # On the chart card, not in the filter bar: comparing narrows nothing, and the bar folds
      # everything behind a disclosure past two controls -- which would have hidden the range.
      click_link "Compare with the previous period"
    end

    it "adds one line, not a second set of columns" do
      # Two column series a month is the crowding this chart was rebuilt to escape.
      expect(chart["names"]).to include("Previous period")
      expect(chart["types"].last).to eq("line")
      expect(chart["types"].count("column")).to be >= 1
    end

    it "puts the same figures in the table, which is the part a screen reader gets" do
      within("tfoot") do
        expect(page).to have_css("th", text: "Previous period")
      end
      expect(page.all("tfoot tr").size).to eq(2)
    end

    it "states the change in words rather than leaving it to be worked out" do
      # A percentage on its own reads as a quantity, and a coloured arrow is a signal only a
      # sighted reader gets.
      expect(page).to have_content(/(up|down) \d+% on the previous period|unchanged from the previous period/)
    end

    it "names the window it is comparing against" do
      expect(page).to have_css("tfoot th", text: /\w{3} \d{4} – \w{3} \d{4}/)
    end
  end
end
