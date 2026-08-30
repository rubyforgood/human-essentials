# Reaching a row's actions in a wide table, and knowing what they are once they are icons.
#
# Reported: "having the action all the way at the end of a horizontal scroll for a user who is
# processing multiple rows is a very frustrating experience." Measured on /distributions at 1440:
# the Actions header started 327px past the right edge and the cell needed 402px of scrolling; at
# 1024 it was 818px. And it did not stay scrolled -- acting on a row reloads, and a reload puts
# scrollLeft back to 0, so a page of 15 rows cost 402 x 15 = 6,030px of dragging.
#
# `bin/design/disclosure-audit.js` has no bearing here; the two audits for this are
# `row-actions-audit.js` and `tooltip-audit.js`. This pins the behaviour so a regression fails the
# suite rather than waiting for someone to run them.
RSpec.describe "Row actions in a wide table", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before { sign_in user }

  def box(selector)
    page.evaluate_script(
      "(() => { const r = document.querySelector(#{selector.to_json}).getBoundingClientRect(); " \
      "return { x: Math.round(r.x), right: Math.round(r.right), width: Math.round(r.width) }; })()"
    ).symbolize_keys
  end

  describe "the actions column on a table that scrolls" do
    before do
      create_list(:distribution, 3, :with_items, organization: organization)
      visit distributions_path
    end

    it "stays against the right edge whether or not the table is scrolled" do
      region = "main .table-scroll"
      cell = "main table.data-table tbody .cell-actions"

      at_rest = box(cell)[:right] - box(region)[:right]

      page.execute_script("const w = document.querySelector('#{region}'); w.scrollLeft = w.scrollWidth")
      # A real scroll, so the controller's listener runs and the shadow follows.
      sleep 0.3
      scrolled = box(cell)[:right] - box(region)[:right]

      expect(at_rest).to eq(0)
      expect(scrolled).to eq(0)
    end

    it "draws its separator only while something is hidden behind it" do
      cell = "main table.data-table tbody .cell-actions"
      border = -> { page.evaluate_script("getComputedStyle(document.querySelector('#{cell}')).borderLeftWidth") }

      expect(border.call).to eq("1px")

      page.execute_script("const w = document.querySelector('main .table-scroll'); w.scrollTo({left: w.scrollWidth, behavior: 'instant'})")
      sleep 0.3

      # Nothing behind it any more, so the line goes: a signal always on is decoration.
      expect(border.call).to eq("0px")
    end

    it "keeps the end-of-scroll shadow clear of the frozen column" do
      # Painting a gradient over a frozen column was a WCAG 1.4.3 failure the first time it was
      # tried at the *start* edge, taking the ink from 9.59:1 to 3.19:1.
      width = page.evaluate_script(
        "getComputedStyle(document.querySelector('main .table-scroll').parentElement)" \
        ".getPropertyValue('--pin-right-width').trim()"
      )
      expect(width).not_to eq("0px")
      expect(width).to eq("#{box("main table.data-table thead .cell-actions")[:width]}px")
    end
  end

  describe "a table that fits" do
    before do
      create(:item_category, organization: organization)
      visit item_categories_path
    end

    it "is left exactly as it was -- no separator, because nothing is behind the column" do
      # `position: sticky` is inert without overflow, so pinning costs a table that fits nothing.
      expect(page).to have_css("main table.data-table")
      expect(page.evaluate_script("document.querySelector('main .table-scroll').dataset.overflow || ''")).to eq("")
    end
  end

  describe "the row menu, which lives in a frozen cell" do
    before do
      create(:storage_location, organization: organization)
      visit storage_locations_path
    end

    it "is moved to the body while open, and put back when it closes" do
      # `position: fixed` escapes an ancestor's overflow but not its stacking context, and the
      # actions column is a `position: sticky` cell now. Trapped there, the open menu resolved
      # below the scroll rail: measured, the rail spanned y=417-441 and the second menu item's
      # centre was y=423, so the click landed on `.table-rail-track` instead. The panel is moved
      # out while it is open -- the same move `table_scroll_controller` already makes for the rail.
      trigger = find("tbody [data-popover-target=trigger]", match: :first)
      panel_id = trigger["aria-controls"]
      expect(panel_id).to be_present

      trigger.click
      expect(page).to have_css("[data-popover-target=panel]", visible: true)
      expect(page.evaluate_script(
        "document.getElementById(#{panel_id.to_json}).parentElement.tagName"
      )).to eq("BODY")

      page.send_keys(:escape)
      expect(page).to have_no_css("[data-popover-target=panel]", visible: true)

      # And nothing is left on the body afterwards -- the property that actually matters, since a
      # stranded panel would outlive the row it belongs to. Asserted this way rather than by
      # looking the panel up again: the table sits in a filter turbo-frame that can re-render in
      # between, and each render issues a fresh id.
      expect(page).to have_no_css("body > [data-popover-target=panel]", visible: :all)
    end

    it "puts its items on top of the scroll rail rather than under it" do
      click_row_action "Edit", row: nil
      expect(page).to have_current_path(/storage_locations\/\d+\/edit/)
    end
  end

  describe "an icon-only row action" do
    before do
      create(:transfer, organization: organization)
      visit transfers_path
    end

    it "carries a name and a tooltip, and no title" do
      control = find("main .cell-actions a[data-tooltip]", match: :first)

      expect(control["aria-label"]).to be_present
      expect(control["data-tooltip"]).to eq(control["aria-label"])
      # A `title` would draw the browser's own tooltip on top of ours a second later. Read with
      # `hasAttribute`, because Capybara reports a missing attribute as nil *or* "" by driver.
      expect(page.evaluate_script(
        "document.querySelector('main .cell-actions a[data-tooltip]').hasAttribute('title')"
      )).to be(false)
    end

    it "names itself on keyboard focus, which a title cannot do at all" do
      page.execute_script("document.querySelector('main .cell-actions [data-tooltip]').focus()")

      expect(page).to have_css(".tip-bubble", text: "View")
      # aria-hidden: the button's aria-label already carries the name, so describing it with the
      # bubble as well would announce the action twice.
      expect(find(".tip-bubble")["aria-hidden"]).to eq("true")

      page.send_keys(:escape)
      expect(page).to have_no_css(".tip-bubble")
    end
  end
end
