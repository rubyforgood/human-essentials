# A set of page tabs behaves as one place: the strip does not move between tabs, and the sidebar
# keeps saying where you are.
#
# Reported on Partner agencies: "the group tab does not have a filter so the card jumps up and
# down" and "when the user clicks on groups, it automatically collapses the side nav." Measured
# before the fix: the strip at y=228 on /partners and y=174 on /partner_groups -- a 54px jump --
# and no sidebar group open at all on the Groups tab.
#
# `bin/design/tab-set-audit.js` checks every set; this pins the one that was reported.
RSpec.describe "A set of page tabs", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before { sign_in user }

  def strip_top
    page.evaluate_script(<<~JS)
      (() => {
        const current = document.querySelector("main nav a[aria-current='page']");
        const strip = current && current.closest("nav");
        return strip ? Math.round(strip.getBoundingClientRect().top + window.scrollY) : null;
      })()
    JS
  end

  describe "Partner agencies" do
    before { create(:partner, organization: organization) }

    it "puts the tab strip at the same height whether or not the tab has filters" do
      # The filter bar is inside the card, under the strip, so a tab without one does not pull
      # everything up 54px. See design.md -- the strip is the landmark; what varies goes below it.
      visit partners_path
      with_filters = strip_top

      visit partner_groups_path
      without_filters = strip_top

      expect(with_filters).to eq(without_filters)
    end

    it "keeps the sidebar section open and the entry marked on the Groups tab" do
      # `active_on` named only the `partners` controller, so landing here left nothing active and
      # the whole Network section shut. GitHub, GitLab, Jira and Linear all keep the section open
      # while you are anywhere inside it.
      visit partner_groups_path

      expect(page).to have_css("button[aria-expanded='true'][aria-controls^='nav-group']")
      expect(page).to have_css("a[aria-current='page']", text: "Partner agencies")
    end
  end

  describe "the item catalogue" do
    it "puts the tab strip at the same height on the tab with no filters" do
      visit items_path
      with_filters = strip_top

      visit item_categories_path
      without_filters = strip_top

      expect(with_filters).to eq(without_filters)
    end

    it "keeps the Inventory section open on Item categories" do
      visit item_categories_path

      expect(page).to have_css("button[aria-expanded='true'][aria-controls^='nav-group']")
      expect(page).to have_css("a[aria-current='page']", text: "Items & inventory")
    end
  end

  describe "filtering from inside the card" do
    before { create(:kit, organization: organization, name: "Newborn kit") }

    it "applies into the frame without disturbing the tab strip" do
      # The frame wraps the table alone: if it wrapped the strip, applying a filter would re-render
      # it with whichever tab the *server* thought was current, throwing away the reader's.
      visit kits_path
      before_filter = strip_top

      click_on "Filters"
      fill_in "Kit name", with: "Newborn"

      expect(page).to have_css("tbody tr", count: 1)
      expect(strip_top).to eq(before_filter)
      expect(page).to have_css("nav a[aria-current='page']", text: "Kits")
    end
  end
end
