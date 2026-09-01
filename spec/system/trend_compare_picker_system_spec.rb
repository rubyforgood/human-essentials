# The Compare control: one searchable, grouped, multi-select list for what the page is about.
#
# It replaced two controls that answered the same question differently -- a single-select in the
# filter bar and a checkbox on every table row. Ticking a row cost a full page load and **1,702px of
# lost scroll** on the 21st of 47 rows, so plotting four things was four reloads and four
# scroll-downs. Here four choices are one request and the list is typed at rather than scrolled.
RSpec.describe "The trend Compare control", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:storage_location) { create(:storage_location, organization: organization) }
  let!(:nappies) { create(:item_category, organization: organization, name: "Nappies") }
  let!(:period) { create(:item_category, organization: organization, name: "Period products") }
  let!(:size_two) { create(:item, organization: organization, name: "Kids Size 2", item_category: nappies) }
  let!(:size_four) { create(:item, organization: organization, name: "Kids Size 4", item_category: nappies) }
  let!(:tampons) { create(:item, organization: organization, name: "Tampons", item_category: period) }
  let!(:wipes) { create(:item, organization: organization, name: "Wipes", item_category: nil) }

  before do
    items = [size_two, size_four, tampons, wipes]
    TestInventory.create_inventory(organization, storage_location.id => items.to_h { |i| [i.id, 900] })
    items.each do |item|
      create(:distribution, :with_items, item: item, organization: organization,
        storage_location: storage_location, issued_at: 1.month.ago)
    end
    sign_in user
    visit historical_trends_distributions_path
  end

  # Waits first: `evaluate_script` does not retry, and Highcharts draws on `connect()`, so reading
  # straight after a navigation sometimes measured a chart that was not there yet.
  def chart
    expect(page).to have_css("svg.highcharts-root")
    page.evaluate_script(<<~JS)
      (() => {
        const el = document.querySelector("[data-controller~='highchart']");
        const c = window.Stimulus.getControllerForElementAndIdentifier(el, "highchart");
        if (!c || !c.chart) return null;
        return { types: c.chart.series.map((s) => s.type),
                 names: c.chart.series.map((s) => s.name),
                 dashes: c.chart.series.map((s) => s.options.dashStyle || null) };
      })()
    JS
  end

  it "starts on everything, with no checkbox in the table" do
    expect(page).to have_css("#filters_compare_trigger", text: "Everything")
    expect(page).to have_no_css("main tbody input[type=checkbox]")
    expect(chart["types"]).to eq(["column"])
  end

  it "lists categories and items under their own headings" do
    open_compare
    within("[role=dialog][aria-label='Choose what to compare']") do
      expect(page).to have_css("[data-compare-picker-target=group]", text: "Categories")
      expect(page).to have_css("[data-compare-picker-target=group]", text: "Items")
      # design.md: a heading over a group is text-xs font-semibold text-slate-500 -- sentence case,
      # no uppercase, no tracking.
      heading = find("[data-compare-picker-target=group]", text: "Categories")
      expect(heading[:class]).to include("text-xs", "font-semibold", "text-slate-500")
      expect(heading[:class]).not_to include("uppercase")
    end
  end

  it "narrows the list as you type, across both groups" do
    open_compare
    within("[role=dialog][aria-label='Choose what to compare']") do
      fill_in "Search categories and items", with: "nappies"
      expect(page).to have_css("[data-compare-picker-target=option]:not([hidden])", count: 1)
      # A heading over nothing is noise, so it goes with its group.
      expect(page).to have_no_css("[data-compare-picker-target=group][data-group='Items']:not([hidden])")

      fill_in "Search categories and items", with: "zzzz"
      expect(page).to have_content("Nothing matches that")
    end
  end

  it "takes a category and an item together, and draws one line each" do
    # Two kinds in one list, because somebody thinking "how are nappies doing" should not have to
    # know first whether nappies is a category or an item.
    compare_with "Nappies", "Tampons"

    expect(chart["types"]).to eq(%w[line line])
    expect(chart["names"]).to eq(["Nappies", "Tampons"])
    expect(chart["dashes"]).to eq(%w[Solid Dash])
  end

  it "narrows the table to what is being compared" do
    compare_with "Period products"

    expect(page).to have_content("Tampons")
    expect(page).to have_no_content("Kids Size 2")
  end

  it "costs one request for several choices" do
    # The reason this control exists. Ticking rows in the table submitted on every change.
    open_compare
    within("[role=dialog][aria-label='Choose what to compare']") do
      check "Nappies", allow_label_click: true
      check "Period products", allow_label_click: true
      # Still on the same page: nothing has been applied yet.
      expect(page).to have_css("[data-compare-picker-target=count]", text: "2 of 4 chosen")
    end
    expect(chart["types"]).to eq(["column"])

    close_compare(applies: true)
    expect(chart["types"]).to eq(%w[line line])
  end

  describe "clearing a choice" do
    before { compare_with "Nappies", "Tampons" }

    it "removes one from its chip under the bar, without opening the control" do
      # The chips are a row under the filter bar: four of them are 659px and the Compare cell is
      # 256, so inside the field they wrapped to three rows and pushed the chart down. They are
      # links, so they need no JavaScript and no second controller.
      expect(chart["names"]).to eq(%w[Nappies Tampons])

      click_link "Stop comparing Nappies"
      expect(page).to have_current_path(/compare_with/)
      expect(chart["names"]).to eq(["Tampons"])
    end

    it "clears everything from inside the panel" do
      open_compare
      click_button "Clear comparison"

      expect(page).to have_css("#filters_compare_trigger", text: "Everything")
      expect(chart["types"]).to eq(["column"])
    end

    it "offers nothing to clear before anything is chosen" do
      visit historical_trends_distributions_path
      open_compare
      expect(page).to have_no_button("Clear comparison")
    end
  end

  describe "the month that is still running" do
    it "is marked off the axis, in words" do
      # "so far" used to be appended to the last axis category on a second line, which made that one
      # label 29px against every other one at 14 -- one column's label twice its neighbours' height,
      # and the axis 12px deeper for one word.
      #
      # Asserted on the label's *text*, not its height. The first version of this measured heights
      # and was **vacuous**: the test browser renders the newline flat -- `tspans: 0`, every label
      # 14px -- so it passed with the two-line label put back. Found by reverting the fix and
      # watching the spec stay green, which is the only reason to bother reverting.
      travel_to Time.zone.local(2026, 6, 12) do
        create(:distribution, :with_items, item: size_two, organization: organization,
          storage_location: storage_location, issued_at: Time.zone.local(2026, 6, 3))
        visit historical_trends_distributions_path
        expect(page).to have_css("svg.highcharts-root")

        labels = page.evaluate_script(<<~JS)
          [...document.querySelectorAll(".highcharts-xaxis-labels text")].map((t) => t.textContent)
        JS

        expect(labels.size).to eq(12)
        expect(labels.grep(/so far/)).to be_empty,
          "the axis still carries \"so far\": #{labels.grep(/so far/).inspect}"
        # Still said, in words, twice -- so dropping it from the axis costs no signal.
        expect(page).to have_content("Jun 2026 is still running")
        expect(page).to have_css("thead th", text: "so far")
      end
    end
  end

  describe "where the chips sit" do
    it "keeps both fields at the app's control height, whatever is chosen" do
      # Chips inside the field made it 46px empty and 166px at four choices, against the date
      # range's 38 -- and pushed the chart card 120px down the page.
      compare_with "Nappies", "Period products", "Kids Size 2", "Kids Size 4"

      heights = page.evaluate_script(<<~JS)
        (() => {
          const h = (s) => Math.round(document.querySelector(s).getBoundingClientRect().height);
          return { range: h("#filters_months_trigger"), compare: h("#filters_compare_trigger") };
        })()
      JS

      expect(heights["compare"]).to eq(heights["range"])
    end

    it "does not move the chart as more are chosen" do
      compare_with "Nappies"
      one = chart_card_top
      compare_with "Period products", "Kids Size 2", "Kids Size 4"

      # One row of chips, 26px, however many there are -- four of them are 659px against the bar's
      # 1,120, so they never wrap at this width.
      expect(chart_card_top).to eq(one)
    end

    it "puts the count in the control and the names underneath" do
      compare_with "Nappies", "Tampons"

      expect(page).to have_css("#filters_compare_trigger", text: "2 chosen")
      # The names are not in the control -- only the count is. They are in the row beneath it.
      expect(page).to have_no_css("#filters_compare_trigger", text: "Nappies")
      expect(page).to have_content("Comparing:")
      expect(page).to have_link("Stop comparing Nappies")
      expect(page).to have_link("Stop comparing Tampons")
    end

    it "names its clear control for what it clears" do
      # The filter bar has its own "Clear all", and that one resets the date range too.
      compare_with "Nappies"
      expect(page).to have_link("Clear comparison")
    end
  end

  describe "the labels around it" do
    it "calls the window a date range, like the six other report pages" do
      expect(page).to have_css("label[for=filters_months_trigger]", text: "Date range")
    end

    it "explains both controls underneath rather than inside them" do
      # design.md: a hint explains a rule an option label should not have to carry, and it goes
      # under the control -- an explanation inside an option is invisible while the list is shut.
      expect(page).to have_content("Whole months. Ends with the current one.")
      expect(page).to have_content("Up to 4. Leave empty for everything.")
    end

    it "does not tell the reader about a cache" do
      # It used to say "Cached, so it may be up to 24 hours behind" -- a sentence about our
      # infrastructure rather than their data, and no longer true besides.
      expect(page).to have_no_content("Cached")
      expect(page).to have_content("How much came in and went out")
    end
  end

  describe "the cap" do
    it "stops at four and says so, in the panel" do
      compare_with "Nappies", "Period products", "Kids Size 2", "Kids Size 4"
      open_compare

      within("[role=dialog][aria-label='Choose what to compare']") do
        expect(page).to have_css("[data-compare-picker-target=count]",
          text: "4 of 4 chosen. Clear one to add another.")
        expect(page).to have_field("Wipes", disabled: true)
        # The four already chosen stay tickable, so there is always a way out of the cap.
        expect(page).to have_field("Nappies", disabled: false, checked: true)
      end
    end
  end
  def chart_card_top
    page.evaluate_script(
      "Math.round(document.querySelector('main .card-surface').getBoundingClientRect().top + window.scrollY)"
    )
  end
end
