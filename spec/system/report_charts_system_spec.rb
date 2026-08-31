# The trend chart, and the sparkline beside each row. See design.md -- "A chart answers one
# question".
#
# The three trend pages used to draw one column series per item with every one of them created
# `visible: false`, so the page opened with an 850px box, a legend of 47 names, and no data. Pressing
# "Select all" was worse: 47 series over 12 months in a 1034px plot is about 1.8px a bar, keyed by a
# legend over a ten-colour palette that five items shared apiece.
#
# Asserted through the live Highcharts instance rather than against the SVG, because what matters is
# how many series are drawn and whether they are visible, and both are properties of the chart
# rather than of any element.
RSpec.describe "Report charts", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:storage_location) { create(:storage_location, organization: organization) }
  let!(:item_a) { create(:item, organization: organization, name: "Kids (Size 2)") }
  let!(:item_b) { create(:item, organization: organization, name: "Wipes") }

  before do
    TestInventory.create_inventory(organization, storage_location.id => {item_a.id => 900, item_b.id => 900})
    [1, 3].each do |months_ago|
      create(:distribution, :with_items, item: item_a, organization: organization,
        storage_location: storage_location, issued_at: months_ago.months.ago)
      create(:distribution, :with_items, item: item_b, organization: organization,
        storage_location: storage_location, issued_at: months_ago.months.ago)
    end
    sign_in user
    visit historical_trends_distributions_path
    expect(page).to have_css("svg.highcharts-root")
  end

  def chart
    page.evaluate_script(<<~JS)
      (() => {
        const el = document.querySelector("[data-controller='highchart']");
        const c = window.Stimulus.getControllerForElementAndIdentifier(el, "highchart");
        if (!c || !c.chart) return null;
        return {
          series: c.chart.series.length,
          visible: c.chart.series.filter((s) => s.visible).length,
          points: c.chart.series[0].points.length,
          height: Math.round(c.chart.chartHeight),
          legendItems: document.querySelectorAll(".highcharts-legend-item").length
        };
      })()
    JS
  end

  it "draws one total per month, visible, without being asked" do
    expect(chart["series"]).to eq(1)
    expect(chart["visible"]).to eq(1), "the chart opens with nothing drawn on it"
    expect(chart["points"]).to eq(12)
  end

  it "needs no legend, and no button before it will draw" do
    expect(chart["legendItems"]).to eq(0)
    expect(page).to have_no_button("Select all")
    expect(page).to have_no_button("Deselect all")
  end

  it "is named for a screen reader" do
    # WCAG 1.1.1. Highcharts renders <svg role="img"> with no accessible name of its own.
    name = page.find("svg.highcharts-root")[:"aria-label"]
    expect(name).to include("total per month")
  end

  it "is short enough to leave the table above the fold" do
    # 850px was taller than the viewport, so the figures were always below it.
    expect(chart["height"]).to be <= 400
  end

  describe "the sparkline in each row" do
    it "gives every item its own trend" do
      rows = page.all("table.data-table tbody tr").size
      expect(rows).to be >= 2
      # tbody only: the tfoot carries an "All items" total row with a sparkline of its own.
      expect(page.all("tbody td.trend svg", visible: :all).size).to eq(rows)
      expect(page.all("tfoot td.trend svg", visible: :all).size).to eq(1)
    end

    it "hides the drawing from a screen reader and says what it shows instead" do
      # The twelve figures are already in the row; what the shape adds is where the peak is, so
      # that is what the text alternative says. An aria-hidden drawing with nothing beside it
      # would leave the cell silent.
      first = page.first("tbody td.trend")
      expect(first.find("svg", visible: :all)[:"aria-hidden"]).to eq("true")
      expect(first.find(".sr-only", visible: :all).text(:all)).to match(/Peaks at [\d,]+ in \w+/)
    end
  end
end
