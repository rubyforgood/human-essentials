# Content that moves after it has been drawn.
#
# The reported case was a shift *between* two pages -- "the card jumps up and down" when switching
# tabs. Auditing the app with Chrome's own `layout-shift` entries found two more, *within* a page,
# and these pin them. See design.md, and `pw bin/design/layout-shift-audit.js`.
RSpec.describe "Layout shift", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before { sign_in user }

  describe "a chart" do
    # Both pages render an empty state instead of a chart when there is nothing to plot, so without
    # this there is no chart to measure and the example passes on nil. The trend chart used to draw
    # a 47-series box whether or not it had data, which is why the older version of this spec needed
    # no setup.
    let(:storage_location) { create(:storage_location, organization: organization) }
    let!(:charted_item) { create(:item, organization: organization) }

    before do
      TestInventory.create_inventory(organization, storage_location.id => {charted_item.id => 400})
      create(:donation, :with_items, item: charted_item, organization: organization,
        storage_location: storage_location, issued_at: 1.month.ago)
      create(:distribution, :with_items, item: charted_item, organization: organization,
        storage_location: storage_location, issued_at: 1.month.ago)
    end

    # The number is not the point and was hard-coded here as 850px, which broke the day the chart
    # got shorter. What has to hold is that the box is reserved *and* matches what the chart draws
    # at -- `shared/_highcharts` takes one height and uses it for both, so they cannot disagree.
    {
      "the monthly trend chart" => "/historical_trends/donations",
      "the activity graph" => "/reports/activity_graph"
    }.each do |what, path|
      it "reserves #{what}'s height before Highcharts renders into it" do
        # The container was an empty div, 0px tall until the chart inflated it on connect() -- so
        # everything under it was thrown down the page a moment after the reader could see it.
        # Measured CLS 0.352 on the trend pages, against Chrome's 0.25 "poor" threshold.
        visit path

        measured = page.evaluate_script(<<~JS)
          (() => {
            const box = document.querySelector("[data-highchart-target=chart]");
            if (!box) return null;
            const el = document.querySelector("[data-controller='highchart']");
            const c = window.Stimulus.getControllerForElementAndIdentifier(el, "highchart");
            return {
              reserved: parseInt(getComputedStyle(box).minHeight, 10),
              drawn: c && c.chart ? Math.round(c.chart.chartHeight) : null
            };
          })()
        JS

        expect(measured).not_to be_nil, "#{path} has no chart to measure"
        expect(measured["reserved"]).to be > 0, "the chart box reserves no height"
        expect(measured["reserved"]).to eq(measured["drawn"]),
          "reserved #{measured["reserved"]}px, drew #{measured["drawn"]}px"
      end
    end
  end

  describe "the donation form's source fields" do
    it "renders only the field that applies, rather than four and then hiding three" do
      # All five were drawn, the grid was two rows tall, and a moment later it was one: everything
      # below jumped 100px on every load. design.md -- the server renders the correct initial
      # state, and JavaScript may reveal but never un-draw.
      visit new_donation_path

      expect(page).to have_css("div.donation_donation_site.hidden", visible: :hidden)
      expect(page).to have_css("div.donation_product_drive.hidden", visible: :hidden)
      expect(page).to have_css("div.donation_manufacturer.hidden", visible: :hidden)
    end

    it "still shows the right field for each source, and hides it again" do
      visit new_donation_path

      select "Product Drive", from: "donation_source"
      expect(page).to have_css("div.donation_product_drive", visible: :visible)
      expect(page).to have_css("div.donation_manufacturer", visible: :hidden)

      select "Manufacturer", from: "donation_source"
      expect(page).to have_css("div.donation_manufacturer", visible: :visible)
      expect(page).to have_css("div.donation_product_drive", visible: :hidden)

      select "Misc. Donation", from: "donation_source"
      expect(page).to have_css("div.donation_manufacturer", visible: :hidden)
      expect(page).to have_css("div.donation_product_drive", visible: :hidden)
    end

    it "keeps a source that is already chosen visible on an edit" do
      donation = create(:donation, organization: organization,
        source: Donation::SOURCES[:manufacturer], manufacturer: create(:manufacturer))

      visit edit_donation_path(donation)

      # The state is read from the record, so editing a manufacturer donation does not start by
      # hiding the manufacturer.
      expect(page).to have_css("div.donation_manufacturer", visible: :visible)
    end
  end
end
