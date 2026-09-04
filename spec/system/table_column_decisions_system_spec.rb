RSpec.describe "Table column decisions", type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before { sign_in(user) }

  # Three decisions taken together on 2026-09-04 and previewed before being built. Each has a
  # negative assertion, because each is the kind of change a later edit undoes without noticing:
  # putting a column back, pilling the quiet state again, printing the whole list.
  describe "the item category list shows the first few items, then a link" do
    let!(:category) { create(:item_category, organization: organization, name: "Adult incontinence") }

    before do
      # Named so the ordering is unambiguous: the cell sorts by name, so A/B/C are the three shown.
      %w[A-item B-item C-item D-item E-item].each do |name|
        create(:item, organization: organization, item_category: category, name: name)
      end
    end

    it "lists three and links to the rest rather than printing all of them" do
      visit item_categories_path

      expect(page).to have_link("A-item")
      expect(page).to have_link("B-item")
      expect(page).to have_link("C-item")
      # The whole point: the tail is not in the cell.
      expect(page).to have_no_link("D-item")
      expect(page).to have_no_link("E-item")
      expect(page).to have_link("+2 more")
    end

    it "sends +N more to the category page, which lists every item" do
      visit item_categories_path
      click_on "+2 more"

      expect(page).to have_current_path(item_category_path(category))
      # The link has to lead somewhere that keeps the promise it makes.
      %w[A-item B-item C-item D-item E-item].each { |name| expect(page).to have_link(name) }
    end
  end

  describe "the partner group reminder column badges only the affirmative state" do
    # `send_reminders: true` is only valid with a deadline day and a real schedule -- the model
    # enforces both, which is why this is spelled out rather than a bare flag.
    let(:schedule) do
      ReminderScheduleService.new(by_month_or_week: "day_of_month", every_nth_month: 1,
        day_of_month: 9).to_ical
    end
    let!(:reminding) do
      create(:partner_group, organization: organization, name: "Sends reminders",
        send_reminders: true, deadline_day: 10, reminder_schedule_definition: schedule)
    end
    let!(:quiet) { create(:partner_group, organization: organization, name: "No reminders", send_reminders: false) }

    it "pills Yes and leaves No as plain text" do
      visit partner_groups_path

      expect(page).to have_css(".rounded-full", text: "Yes")
      expect(page).to have_content("No")
      # The negative half. A neutral pill on the ordinary row reads as a badge on every row, which
      # is what design.md's "badges mark the exception" is against.
      expect(page).to have_no_css(".rounded-full", text: /\ANo\z/)
    end
  end

  describe "the distributions table fits without scrolling sideways" do
    let!(:distribution) { create(:distribution, organization: organization, comment: "a comment nobody scans") }

    it "does not carry source inventory, shipping cost or comments" do
      visit distributions_path

      headers = page.all("table.data-table thead th").map { |th| th.text.strip }
      expect(headers).to include("Partner", "Delivery method", "Status")
      expect(headers).not_to include("Source inventory", "Shipping cost", "Comments")
    end

    # Dropping them from the list is a decision about what is worth scanning, not about what is
    # worth recording -- so the export must still carry all three.
    it "still exports all three" do
      # `filters: {}` and not the default `[]`: the service indexes into it with `[:by_item_id]`,
      # which raises on an Array.
      exporter = Exports::ExportDistributionsCSVService.new(distributions: Distribution.all,
        organization: organization, filters: {})

      # `generate_csv_data`'s first row is the header row -- the public path, and what actually
      # lands in the file.
      expect(exporter.generate_csv_data.first).to include("Source Inventory", "Shipping Cost", "Comments")
    end
  end
end
