# Plotting rows from the table, and the cap on how many.
#
# This is the answer to the question the stacked chart could not answer: a chart's series count has
# to be a constant the design picks, and a breakdown by anything the data supplies -- 47 items, or
# an unbounded number of categories -- is not that. So the table lists everything and the reader
# ticks what they want plotted, which is Google Analytics 4's shape.
#
# The cap is four, and it is not arbitrary. Measured: four dash patterns (solid, dashed, dotted,
# dash-dot) are the most that stay distinct at 2px, and on this bank's real figures a fourth direct
# label is the first to collide. Colour cannot be the distinguisher at all -- of 28 pairs from an
# eight-colour candidate set, none clears 3:1 under normal vision and three kinds of colour
# blindness.
RSpec.describe "Plotting rows from the trend table", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:storage_location) { create(:storage_location, organization: organization) }
  let!(:items) do
    %w[Alpha Bravo Charlie Delta Echo Foxtrot].map do |name|
      create(:item, organization: organization, name: name)
    end
  end

  before do
    TestInventory.create_inventory(organization, storage_location.id => items.to_h { |i| [i.id, 900] })
    items.each do |item|
      create(:distribution, :with_items, item: item, organization: organization,
        storage_location: storage_location, issued_at: 1.month.ago)
    end
    sign_in user
    visit historical_trends_distributions_path
  end

  def chart
    page.evaluate_script(<<~JS)
      (() => {
        const el = document.querySelector("[data-controller~='highchart']");
        const c = window.Stimulus.getControllerForElementAndIdentifier(el, "highchart");
        if (!c || !c.chart) return null;
        return {
          types: c.chart.series.map((s) => s.type),
          names: c.chart.series.map((s) => s.name),
          dashes: c.chart.series.map((s) => s.options.dashStyle || null)
        };
      })()
    JS
  end

  def plot(name) = check("Plot #{name}")

  it "shows the total until a row is ticked" do
    expect(chart["types"]).to eq(["column"])
    expect(page).to have_content("Tick up to 4 rows")
  end

  it "plots a ticked row as a line" do
    plot "Alpha"

    expect(page).to have_content("1 of 4 plotted")
    expect(chart["types"]).to eq(["line"])
    expect(chart["names"]).to eq(["Alpha"])
  end

  it "tells the lines apart by dash pattern, not by colour" do
    # Of 28 pairs from an eight-colour candidate set, none clears 3:1 across normal vision and three
    # kinds of colour blindness -- so colour cannot be what a reader uses, and the pattern must be.
    plot "Alpha"
    plot "Bravo"
    plot "Charlie"

    expect(chart["dashes"]).to eq(%w[Solid Dash Dot])
    expect(chart["dashes"].uniq.size).to eq(3)
  end

  describe "the cap" do
    before { %w[Alpha Bravo Charlie Delta].each { |n| plot n } }

    it "stops at four and says why, visibly" do
      # Visible, not sr-only. A greyed-out box whose explanation only a screen reader gets is the
      # fault this app already fixed once, in the row action menus.
      expect(page).to have_content("4 of 4 plotted. Clear one to plot another.")
      expect(chart["names"].size).to eq(4)
    end

    it "disables the rows that would be a fifth" do
      expect(page).to have_field("Plot Echo", disabled: true)
      expect(page).to have_field("Plot Foxtrot", disabled: true)
    end

    it "leaves the four already chosen tickable, so one can be cleared" do
      expect(page).to have_field("Plot Alpha", disabled: false, checked: true)

      uncheck "Plot Alpha"
      expect(page).to have_content("3 of 4 plotted")
      expect(page).to have_field("Plot Echo", disabled: false)
    end
  end

  it "keeps the window and the category when a row is ticked" do
    # The checkboxes are in the table, which is outside the filter bar's form, so they carry the
    # window and category forward as hidden fields. Without that, ticking a row would silently
    # reset both.
    find("#filters_months_trigger").click
    click_button "Last 6 months"
    expect(page).to have_button("Last 6 months")

    plot "Alpha"
    expect(page).to have_button("Last 6 months")
    expect(page).to have_current_path(/filters%5Bmonths%5D/)
  end
end
