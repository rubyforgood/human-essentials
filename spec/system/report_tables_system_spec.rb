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
      expect(page).to have_css("main .data-table tbody th")

      # Compared with the row's own data cells rather than against a number. The first version
      # asserted 16px and broke the day the table took `dense` padding -- which is the same fault
      # as `layout_shift_system_spec` pinning "850px". The rule is that a row header is padded
      # *like a cell*, whatever a cell is padded by on that table.
      inset = page.evaluate_script(<<~JS)
        (() => {
          const row = document.querySelector("main .data-table tbody tr");
          if (!row) return null;
          const px = (el) => [parseFloat(getComputedStyle(el).paddingLeft),
                              parseFloat(getComputedStyle(el).paddingRight)];
          return { header: px(row.querySelector("th")), cell: px(row.querySelector("td.quantity")) };
        })()
      JS

      expect(inset).not_to be_nil, "the trend table no longer has a row header to check"
      expect(inset["header"]).to eq(inset["cell"])
      expect(inset["header"][0]).to be > 0, "the row header has no left padding at all"
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

  describe "every report table" do
    # A report with no data renders an empty state and no table at all, so the caption examples
    # would have passed on nothing. One donation, one distribution and one request put a table on
    # each of the five pages.
    let!(:reported_item) { create(:item, organization: organization) }
    let!(:partner) { create(:partner, organization: organization) }

    before do
      TestInventory.create_inventory(organization, storage_location.id => {reported_item.id => 500})
      create(:donation, :with_items, item: reported_item, organization: organization,
        storage_location: storage_location, issued_at: Time.current)
      create(:distribution, :with_items, item: reported_item, organization: organization,
        partner: partner, storage_location: storage_location, issued_at: Time.current)
      create(:request, :with_item_requests, organization: organization, partner: partner)
    end

    # design.md: "Every table gets a <caption> (visually hidden) saying what it lists." The three
    # itemized reports had none -- the trend and county tables did, so the rule was half kept and
    # nothing was checking the other half.
    {
      "/reports/itemized_donations" => "Donations received",
      "/reports/itemized_distributions" => "Distributions in the selected period",
      "/reports/itemized_requests" => "Items requested",
      "/reports/activity_graph" => "received against",
      "/historical_trends/distributions" => "by item and month"
    }.each do |path, phrase|
      it "names itself in a caption on #{path}" do
        visit path
        caption = page.first("main table caption", visible: :all)
        expect(caption).not_to be_nil, "#{path} has a table with no <caption>"
        expect(caption.text(:all)).to include(phrase)
      end
    end

    # design.md, "Sentence case for everything a person reads". The three trend pages and the
    # activity graph were Title Case, and the reports hub that links to them was not -- so the link
    # said "Activity graph" and the page it opened said "Activity Graph".
    {
      "/historical_trends/distributions" => "Monthly distributions",
      "/historical_trends/donations" => "Monthly donations",
      "/historical_trends/purchases" => "Monthly purchases",
      "/reports/activity_graph" => "Activity graph"
    }.each do |path, heading|
      it "is titled in sentence case on #{path}" do
        visit path
        expect(page).to have_css("h1", text: heading, exact_text: true)
      end
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
