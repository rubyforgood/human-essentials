# The window on a chart that buckets by month. See design.md -- "A period chart takes a period
# range".
#
# The three trend pages had no date control at all: the window was welded into the service as
# `1.year.ago.beginning_of_month..Time.current` with twelve fixed buckets, so they were the only
# reports that could not be re-aimed. The picker is month-granular rather than day-granular on
# purpose -- a day range over a monthly chart produces partial months at both ends, and a short
# column with no explanation reads as a fall rather than as an artefact of the range.
RSpec.describe "Trend month range", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:storage_location) { create(:storage_location, organization: organization) }
  let!(:item) { create(:item, organization: organization, name: "Kids (Size 2)") }

  before do
    TestInventory.create_inventory(organization, storage_location.id => {item.id => 5000})
    # Including this month, so a window clamped down to one month still has a table to count --
    # with nothing in it the page renders the empty state and there are no columns at all.
    [0, 1, 4, 9].each do |months_ago|
      create(:distribution, :with_items, item: item, organization: organization,
        storage_location: storage_location, issued_at: months_ago.months.ago)
    end
    sign_in user
  end

  # Item + Trend + one per month + Total.
  def month_columns = page.all("main table thead th").size - 3

  describe "where the control sits" do
    it "is in the filter bar, at the width every other report's filter gets" do
      # It shipped in the page header's `actions:` slot, which is a right-aligned flex row sized
      # for buttons: the same control came out 142px wide and hard right, against 271px and
      # left-aligned on the six report pages that already had one. A filter is not a page action.
      visit historical_trends_distributions_path

      box = page.evaluate_script(<<~JS)
        (() => {
          const t = document.querySelector("#filters_months_trigger");
          const h1 = document.querySelector("main h1");
          if (!t || !h1) return null;
          const a = t.getBoundingClientRect(), b = h1.getBoundingClientRect();
          return { width: Math.round(a.width), left: Math.round(a.left), headingLeft: Math.round(b.left),
                   inHeaderActions: !!t.closest('[data-page-header="actions"]') };
        })()
      JS

      expect(box["inHeaderActions"]).to be(false)
      expect(box["left"]).to eq(box["headingLeft"]), "the filter is not aligned with the page"
      expect(box["width"]).to be >= 240
    end
  end

  describe "the filter bar's summary" do
    it "offers nothing to clear until the window is not the default one" do
      # The two visible month fields inside the popover were being counted as filters in their own
      # right, so "Clear all" appeared on a page nobody had filtered. The summary controller skipped
      # `type="date"` inside the date popover and `<input type="month">` is not that.
      # `have_link`, not `have_button`: "Clear all" is an anchor, and `have_no_button` passed
      # against it whatever the state -- the negative assertion was vacuous before this.
      visit historical_trends_distributions_path
      expect(page).to have_css("#filters_months_trigger")
      expect(page).to have_no_link("Clear all")

      click_button "Last 12 months"
      click_button "Last 6 months"
      # Wait for the reload before looking: choosing a preset submits the bar, and the summary is
      # rendered by the server response rather than by the click.
      expect(page).to have_current_path(/filters%5Bmonths%5D/)
      expect(page).to have_link("Clear all")
    end
  end

  describe "the default window" do
    it "is the last twelve months" do
      visit historical_trends_distributions_path
      expect(page).to have_button("Last 12 months")
      expect(month_columns).to eq(12)
    end
  end

  describe "choosing a preset" do
    it "re-aims the chart and the table, and says so in the URL" do
      visit historical_trends_distributions_path
      click_button "Last 12 months"
      click_button "Last 6 months"

      expect(page).to have_button("Last 6 months")
      expect(month_columns).to eq(6)
      # In the query string, so a chosen window survives a reload and can be linked to.
      expect(page).to have_current_path(/filters%5Bmonths%5D/)
    end
  end

  describe "the edges of the window" do
    it "offers the current month as the latest choosable one" do
      # Not restricted to completed months: "how are we doing this month" is the question people
      # ask most of a trend, and a control that cannot answer it sends them to count rows.
      visit historical_trends_distributions_path
      click_button "Last 12 months"

      this_month = Time.zone.today.strftime("%Y-%m")
      expect(page.find("#filters_months_end", visible: :all)[:max]).to eq(this_month)
      expect(page.find("#filters_months_start", visible: :all)[:max]).to eq(this_month)
    end

    it "clamps a window that reaches past the current month" do
      visit "#{historical_trends_distributions_path}?filters%5Bmonths%5D=2099-01+-+2099-06"
      expect(month_columns).to eq(1)
      expect(page).to have_css("#filters_months_end[value='#{Time.zone.today.strftime("%Y-%m")}']", visible: :all)
    end

    it "falls back to the default rather than raising on a hand-edited range" do
      visit "#{historical_trends_distributions_path}?filters%5Bmonths%5D=nonsense"
      expect(page).to have_button("Last 12 months")
      expect(month_columns).to eq(12)
    end
  end

  describe "a month that has not finished" do
    it "says so on the column and in the subtitle" do
      # Mid-month, so the last bucket is genuinely partial. On the last day of a month it is not,
      # and the marking correctly disappears -- which is why this travels rather than trusting
      # whatever today happens to be.
      travel_to Time.zone.local(2026, 6, 12) do
        visit historical_trends_distributions_path

        expect(page).to have_css("thead th", text: "so far")
        expect(page).to have_content("Jun 2026 is still running")
      end
    end

    it "says nothing on the last day of the month, when it is not partial" do
      travel_to Time.zone.local(2026, 6, 30) do
        visit historical_trends_distributions_path

        expect(page).to have_no_css("thead th", text: "so far")
        expect(page).to have_no_content("is still running")
      end
    end
  end

  describe "records dated after today" do
    let!(:scheduled) do
      create(:distribution, :with_items, item: item, organization: organization,
        storage_location: storage_location, issued_at: 3.weeks.from_now)
    end

    it "leaves them out of the trend and says that it has" do
      # A trend is what happened, not what is booked. Dropping them silently would make the chart
      # quietly wrong for anyone who knows they exist.
      visit historical_trends_distributions_path

      expect(page).to have_content("scheduled for after today and are not counted here")
    end

    it "says nothing on a page where nothing can be scheduled" do
      # A donation is recorded after the fact, so the callout would be noise.
      visit historical_trends_donations_path
      expect(page).to have_no_content("scheduled for after today")
    end
  end
end
