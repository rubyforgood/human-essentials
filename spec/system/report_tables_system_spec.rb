# The report tables, against the design system. See design.md -- "Tables".
#
# Reported on the monthly distributions table: padding missing on both sides, and no pagination.
# The padding was a hole in the design system rather than a mistake in the view -- `.data-table`
# named `thead th`, `tbody td` and `tfoot th`, and never the fourth combination, so any table that
# labels its rows with `<th scope="row">` lost its cell padding entirely. Three did.
#
# Auditing the rest of the reports for the same class of fault turned up a second one: two of them
# marked "below the on-hand minimum" with Bootstrap's `table-danger`, which is defined nowhere since
# ADR 0011 and drew nothing at all.
RSpec.describe "Report tables", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:storage_location) { create(:storage_location, organization: organization) }

  before { sign_in user }

  describe "a table whose first column is a row header" do
    # The trend page shows an empty state until there is something to chart, and an empty state has
    # no table to measure -- so the first version of this spec passed nothing and failed on nil.
    let!(:item) { create(:item, organization: organization) }

    before do
      TestInventory.create_inventory(organization, storage_location.id => {item.id => 300})
      create(:distribution, :with_items, item: item, organization: organization,
        storage_location: storage_location, issued_at: 2.months.ago)
    end

    it "pads it like every other cell" do
      # Measured, not asserted against a class name: the rule lives in application.css and the
      # symptom is the text sitting flush against the edge of the card.
      visit historical_trends_distributions_path

      inset = page.evaluate_script(<<~JS)
        (() => {
          const cell = document.querySelector("main .data-table tbody th");
          if (!cell) return null;
          const cs = getComputedStyle(cell);
          return { left: parseFloat(cs.paddingLeft), right: parseFloat(cs.paddingRight) };
        })()
      JS

      expect(inset).not_to be_nil, "the trend table no longer has a row header to check"
      expect(inset["left"]).to eq(16)
      expect(inset["right"]).to eq(16)
    end
  end

  describe "an item below its on-hand minimum" do
    let!(:item) { create(:item, organization: organization, on_hand_minimum_quantity: 500) }

    before do
      TestInventory.create_inventory(organization, storage_location.id => {item.id => 1})
      create(:distribution, :with_items, item: item, organization: organization,
        storage_location: storage_location, issued_at: Time.current)
    end

    it "says so in words, not in a colour that does not exist" do
      visit reports_itemized_distributions_path

      # `table-danger` is Bootstrap's. Nothing defines it, so a cell carrying it renders exactly
      # like a cell that does not -- the warning was invisible rather than subtle.
      expect(page).to have_no_css(".table-danger")
      expect(page).to have_content("Below minimum")
    end
  end

  describe "pagination" do
    # Answering the question rather than leaving it open: no, and it should not be. Every report
    # here is one row per *item*, so the length is bounded by the bank's catalogue -- dozens --
    # while an index table is one row per transaction and unbounded. A report is also read whole,
    # exported whole and printed whole, and a pager breaks all three. Recorded in
    # docs/design-decisions.md; this pins it so the absence reads as a decision.
    it "is absent from the report tables, deliberately" do
      %w[/reports/itemized_distributions /reports/itemized_requests /historical_trends/distributions].each do |path|
        visit path
        expect(page).to have_no_css("[data-pagination]"), "#{path} has grown a pager"
      end
    end
  end
end
