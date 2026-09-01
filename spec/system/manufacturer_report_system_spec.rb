# The manufacturer donations report. See design.md -- "Tables".
#
# Reported as not looking right, and six faults were behind it. Four were consequences of the same
# thing: it was the only report in the app that was not a table. The list was a
# `<div class="manufacturer">` per row, and that class is defined nowhere -- so the only link into a
# manufacturer rendered in near-black with no underline. With no columns there was no unit on the
# figure, no total, nothing aligned to read down, and the date the query already selected was never
# shown.
RSpec.describe "Manufacturer donations report", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:storage_location) { create(:storage_location, organization: organization) }
  let(:item) { create(:item, organization: organization) }

  def donate(manufacturer, quantity, issued_at)
    create(:donation, :with_items, item: item, item_quantity: quantity,
      source: Donation::SOURCES[:manufacturer], manufacturer: manufacturer,
      organization: organization, storage_location: storage_location, issued_at: issued_at)
  end

  before { sign_in user }

  context "with a few manufacturers" do
    let!(:big) { create(:manufacturer, organization: organization, name: "Kimberly-Clark") }
    let!(:small) { create(:manufacturer, organization: organization, name: "Ontex") }

    before do
      donate(big, 500, 1.week.ago)
      donate(small, 100, 2.weeks.ago)
      visit reports_manufacturer_donations_summary_path
    end

    it "is a table, with the columns the data already had" do
      expect(page).to have_css("main table.data-table")
      expect(page).to have_no_css(".manufacturer")

      headers = page.all("main thead th").map { |th| th.text(:all).strip }
      expect(headers).to include("Manufacturer", "Items donated", "Share", "Last donation")
    end

    it "orders it biggest first and totals it" do
      names = page.all("main tbody th[scope=row]").map(&:text)
      expect(names).to eq(["Kimberly-Clark", "Ontex"])

      within("tfoot") do
        expect(page).to have_css("th", text: "All manufacturers")
        expect(page).to have_content("600")
      end
    end

    it "gives the figure a unit and shows the date" do
      # "(2,901)" was sum(line_items.quantity) printed bare, beside a stat labelled "Items donated"
      # holding the same number -- one figure, shown twice, named once.
      within("main tbody tr", match: :first) do
        expect(page).to have_css("td.quantity", text: "500")
        expect(page).to have_css("td.date", text: Regexp.new(1.week.ago.year.to_s))
      end
    end

    it "shows each manufacturer's share as a bar with a figure beside it" do
      # The bar is the graphical object; the percentage is its text alternative, so the column says
      # the same thing to a reader who cannot see the fill.
      within("main tbody tr", match: :first) do
        expect(page).to have_css(".share-fill", visible: :all)
        expect(page).to have_css(".share-figure", text: "83%")
      end
      expect(page.first(".share-fill", visible: :all)[:"aria-hidden"] ||
             page.first(".share-track", visible: :all)[:"aria-hidden"]).to eq("true")
    end

    it "uses the design system's row action, not a bare link" do
      # design.md: every visible control in an actions column is an icon at size-7, named by
      # aria-label. The old page's only link was unstyled text.
      expect(page).to have_css("main tbody td.cell-actions a i.bi-eye")
      expect(page).to have_link("View Kimberly-Clark")
    end

    it "puts New donation in the page header" do
      # It used to sit in the card body, between the list and the footer, which is where a form's
      # submit goes.
      within("[data-page-header='actions']") { expect(page).to have_link("New donation") }
      expect(page).to have_css("main table")
    end

    it "counts manufacturers as a figure, without repeating its own label" do
      # It read "Manufacturers donating: 1 Manufacturer" -- the word twice, and a capital M
      # mid-value against sentence case.
      expect(page).to have_content("Manufacturers donating")
      expect(page).to have_no_content(/\d+ Manufacturers?\b/)
    end
  end

  context "with more manufacturers than the page shows" do
    before do
      11.times { |i| donate(create(:manufacturer, organization: organization, name: "Maker #{i}"), (i + 1) * 10, 3.days.ago) }
      visit reports_manufacturer_donations_summary_path
    end

    it "says what it is showing ten of" do
      # The list was capped at ten and never said so.
      expect(page.all("main tbody tr").size).to eq(10)
      expect(page).to have_content("The 10 largest of 11 manufacturers who donated")
      within("tfoot") { expect(page).to have_css("th", text: "These 10") }
    end
  end
end
