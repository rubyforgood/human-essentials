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

  def chart
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
end
