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
    it "reserves its height before Highcharts renders into it" do
      # The container was an empty div, 0px tall until the chart inflated it on connect() -- so the
      # buttons under it and the whole table card were thrown 850px down the page a moment after
      # the reader could see them. Measured CLS 0.352, against Chrome's 0.25 "poor" threshold.
      visit historical_trends_donations_path

      reserved = page.evaluate_script(
        "getComputedStyle(document.querySelector('[data-highchart-target=chart]')).minHeight"
      )
      expect(reserved).to eq("850px")
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
