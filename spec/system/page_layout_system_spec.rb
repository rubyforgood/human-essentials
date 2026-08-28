# The layout invariants nothing else asserts.
#
# Every defect pinned here shipped on a page that returned 200, carried no legacy class, threw no
# JS error and passed the whole suite. A passing spec is not evidence that a page is built the way
# the design system builds pages -- so these read geometry and structure rather than content.
RSpec.describe "Page layout", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  before { sign_in(organization_admin) }

  # The gap under a page heading is the page header's own `mb-6` and nothing else. It measured 72px
  # on fourteen pages, which is what two page wrappers meeting produces: the first one's bottom
  # padding stacked on the second one's top padding.
  #
  # rack-mini-profiler injects its own markup into every development page, so it is excluded here
  # for the same reason the browser audits exclude it.
  def gap_below_heading
    page.evaluate_script(<<~JS)
      (() => {
        const h1 = document.querySelector("h1");
        const hdr = h1 && h1.closest("div.mb-6");
        if (!hdr) return null;
        const after = [...document.querySelectorAll("main *")]
          .filter(e => !e.closest(".profiler-results, .profiler-result"))
          .filter(e => !hdr.contains(e))
          .filter(e => hdr.compareDocumentPosition(e) & Node.DOCUMENT_POSITION_FOLLOWING)
          .filter(e => e.getBoundingClientRect().height > 8 && e.getBoundingClientRect().width > 8);
        if (!after.length) return null;
        return Math.round(after[0].getBoundingClientRect().top - hdr.getBoundingClientRect().bottom);
      })()
    JS
  end

  def page_wrappers
    page.evaluate_script('document.querySelectorAll("main > .px-4.py-6").length')
  end

  describe "the organization page" do
    before { visit organization_path }

    it "puts the design system's 24px between the heading and the first card" do
      expect(page_wrappers).to eq(1)
      expect(gap_below_heading).to eq(24)
    end

    it "renders the users list as a data table inside a scroll region" do
      expect(page).to have_css(".table-scroll[role='region'] table.data-table")
      # Bootstrap's `.table` is defined nowhere in this design system, so it styled nothing.
      expect(page).to have_no_css("table.table")
    end

    it "puts Edit in the page header rather than in a card, because it acts on the record" do
      in_header = page.evaluate_script(<<~JS)
        (() => {
          const el = [...document.querySelectorAll("a, button")]
            .find(e => e.textContent.trim() === "Edit");
          if (!el) return null;
          return !!el.closest("div.mb-6") && !el.closest("section.card-surface");
        })()
      JS
      expect(in_header).to be true
    end

    it "positions the footer button without a float" do
      expect(page).to have_no_css("[class*='float-']")
    end

    # The last band dropped to `pt-4` on the assumption that the card supplied the bottom padding.
    # It does not -- the card is rendered `padded: false` -- so the final field sat 1px from the
    # card's bottom edge while the seven bands above it had 16.
    it "gives every band the same padding, including the last" do
      paddings = page.evaluate_script(<<~JS)
        [...document.querySelectorAll("section.card-surface h3")]
          .map(h => { const cs = getComputedStyle(h.nextElementSibling);
                      return cs.paddingTop + "/" + cs.paddingBottom; })
      JS
      expect(paddings).to all(eq("16px/16px"))
      expect(paddings.length).to be >= 2
    end
  end

  describe "the users page" do
    before { visit users_path }

    it "has one page wrapper and a 24px gap under the heading" do
      expect(page_wrappers).to eq(1)
      expect(gap_below_heading).to eq(24)
    end

    # `.pin-col` freezes a column so that a table which scrolls sideways keeps its identifying
    # column in view. Two columns never scroll, and pinned, Name held 417px of a 740px phone.
    it "does not freeze a column on a table that cannot scroll sideways" do
      expect(page).to have_css("table.data-table")
      expect(page).to have_no_css("table.data-table .pin-col")
    end

    # The card opened with an empty `border-b` strip: a hand-written header holding nothing, drawing
    # a hairline across the top of the card for no reason.
    it "draws no empty card header" do
      # Any depth, not `> div`: the card wraps whatever it yields, so a hand-written header inside
      # it is a grandchild. Written as a direct-child selector this assertion passed against the
      # very markup it was meant to catch.
      empties = page.evaluate_script(<<~JS)
        [...document.querySelectorAll("section.card-surface div")]
          .filter(d => d.className.split(/\\s+/).includes("border-b") && !d.textContent.trim()).length
      JS
      expect(empties).to eq(0)
    end
  end
end
