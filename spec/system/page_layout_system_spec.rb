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

  # The *gutter*, not the whole padding string. Counting `.px-4.py-6` was the same mistake the
  # first version of the audit check made: a header wrapper opening `pt-6` is still a page wrapper,
  # and 17 templates were missed by looking for the exact class string.
  def page_wrappers
    page.evaluate_script(%(document.querySelectorAll("main > .px-4.lg\\\\:px-8").length))
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
  describe "the organization settings form" do
    before { visit edit_organization_path }

    it "has one page wrapper and the design system's 24px under the heading" do
      expect(page_wrappers).to eq(1)
      expect(gap_below_heading).to eq(24)
    end

    # A <legend> is rendered *in* its fieldset's top border and the browser cuts a gap for it, so
    # `border-t` on the fieldset drew a rule starting where the legend text ended. The section
    # legends are full-bleed bands now, like the organization page this form edits.
    it "bands its sections instead of bordering the fieldsets" do
      bands = page.evaluate_script(<<~JS)
        [...document.querySelectorAll("section.card-surface fieldset.form-section")].map(fs => {
          const lg = fs.querySelector("legend");
          return { border: getComputedStyle(fs).borderTopWidth,
                   fullWidth: Math.round(lg.getBoundingClientRect().width) >=
                              Math.round(fs.getBoundingClientRect().width) - 1 };
        })
      JS
      expect(bands.length).to be >= 8
      expect(bands.map { |b| b["border"] }).to all(eq("0px"))
      expect(bands.map { |b| b["fullWidth"] }).to all(be true)
    end

    # 24px rows flush against each other before: the floor of WCAG 2.5.8 with no separation.
    # GOV.UK pairs a 40px control with a 10px gap, Material 3 asks 48dp, Apple 44pt.
    it "gives radio options a 32px row and 8px between them" do
      rows = page.evaluate_script(<<~JS)
        (() => {
          const groups = {};
          document.querySelectorAll("section.card-surface input[type=radio]")
            .forEach(r => (groups[r.name] = groups[r.name] || []).push(r));
          return Object.values(groups).map(els => {
            const rects = els.map(e => e.parentElement.getBoundingClientRect())
                             .sort((a, z) => a.top - z.top);
            return { h: Math.round(rects[0].height),
                     gap: rects.length > 1 ? Math.round(rects[1].top - rects[0].bottom) : null };
          });
        })()
      JS
      expect(rows.length).to be >= 10
      expect(rows.map { |r| r["h"] }).to all(be >= 32)
      expect(rows.map { |r| r["gap"] }).to all(eq(8))
    end

    # The field was 44px wide with a 92px placeholder, so "Deadline day" was cut off mid-word.
    # Placeholder text does not affect scrollWidth, so it is measured against the content box.
    it "leaves room for every placeholder it sets" do
      truncated = page.evaluate_script(<<~JS)
        (() => {
          const cv = document.createElement("canvas").getContext("2d");
          return [...document.querySelectorAll("section.card-surface input[placeholder]")]
            .filter(i => i.placeholder && i.clientWidth > 0)
            .filter(i => {
              const cs = getComputedStyle(i);
              cv.font = `${cs.fontStyle} ${cs.fontWeight} ${cs.fontSize} ${cs.fontFamily}`;
              const avail = i.clientWidth - parseFloat(cs.paddingLeft) - parseFloat(cs.paddingRight);
              return cv.measureText(i.placeholder).width > avail;
            })
            .map(i => i.placeholder);
        })()
      JS
      expect(truncated).to be_empty
    end

    # Trix draws its own icons as SVG data-URIs. This app retired Font Awesome so it would have
    # one icon set; the toolbar is Bootstrap Icons like everything else.
    it "styles the rich text toolbar like the rest of the app" do
      toolbar = page.evaluate_script(<<~JS)
        (() => {
          const btn = document.querySelector("trix-toolbar .trix-button--icon-bold");
          if (!btn) return null;
          const r = btn.getBoundingClientRect();
          const grp = btn.closest(".trix-button-group");
          return { w: Math.round(r.width), h: Math.round(r.height),
                   bootstrapIcon: btn.className.includes("bi-type-bold"),
                   trixSvg: getComputedStyle(btn, "::before").backgroundImage,
                   glyphFont: getComputedStyle(btn, "::before").fontFamily,
                   groupRadius: getComputedStyle(grp).borderRadius };
        })()
      JS
      expect(toolbar).not_to be_nil
      expect(toolbar["w"]).to eq(32)
      expect(toolbar["h"]).to eq(32)
      expect(toolbar["bootstrapIcon"]).to be true
      expect(toolbar["trixSvg"]).to eq("none")
      expect(toolbar["glyphFont"]).to include("bootstrap-icons")
      expect(toolbar["groupRadius"]).to eq("8px")
    end
  end
end
