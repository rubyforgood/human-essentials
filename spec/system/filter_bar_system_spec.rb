# A single filter is shown, never hidden -- and a filter checkbox sits on the line of the control
# beside it.
#
# Reported on Items & inventory: "if there is a single filter, is there a need to have a filter
# drop down and then just a single category to filter appear" and "the check box is floating and
# not centre aligned to the drop down". See design.md.
RSpec.describe "The filter bar", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before { sign_in user }

  def centre_of(selector)
    page.evaluate_script(
      "(() => { const r = document.querySelector(#{selector.to_json}).getBoundingClientRect(); " \
      "return Math.round(r.top + r.height / 2); })()"
    )
  end

  describe "with one filter" do
    before do
      create(:vendor, organization: organization)
      visit vendors_path
    end

    it "shows the control instead of a Filters button" do
      # Measured across the eighteen filtered pages: four have a single control, and on two of them
      # -- this page and /donation_sites -- it is a checkbox. A button, a chevron and a panel to
      # conceal one tick box is a click that buys nothing.
      expect(page).to have_no_css("[data-filter-toggle]")
      expect(page).to have_css("main form input[type='checkbox']", visible: :visible)
    end

    it "still applies, and still offers Clear all" do
      expect(page).to have_no_link("Clear all")

      check "Also include inactive vendors"

      expect(page).to have_link("Clear all")
      expect(page).to have_current_path(/include_inactive_vendors=1/)
    end
  end

  describe "with two filters" do
    before do
      create(:item, organization: organization)
      visit items_path
    end

    it "shows both rather than folding them" do
      # Two is what fits on a line. On this page the second control is an *include inactive* toggle
      # -- a modifier of the first filter rather than a second one -- which is why it was reported
      # as "the only filter is NDBN reporting category".
      expect(page).to have_no_css("[data-filter-toggle]")
      expect(page).to have_css("main form select", visible: :visible)
      expect(page).to have_css("main form input[type='checkbox']", visible: :visible)
    end

    it "puts the checkbox on the same line as the control beside it" do
      # The select brings 26px of label above a 38px control, so it lands at the bottom of its
      # stretched grid cell; the checkbox has no label and landed at the top -- measured 35px apart,
      # which read as a ragged row and as padding missing above the checkbox.
      expect(centre_of("main form input[type='checkbox']"))
        .to eq(centre_of("main form select"))
    end

    it "gives the band equal padding above and below" do
      # The row's `mb-3` exists to separate it from the panel, and inline there is no panel: it made
      # the band bottom-heavy at 16 above and 29 below, reported as the padding not being equal.
      gaps = page.evaluate_script(<<~JS)
        (() => {
          const form = document.querySelector("main form[data-controller~='auto-submit']");
          const row = form.querySelector("[data-filter-bar-row]");
          const f = form.getBoundingClientRect(), r = row.getBoundingClientRect();
          const cs = getComputedStyle(form);
          return { above: cs.paddingTop, below: cs.paddingBottom,
                   trailing: getComputedStyle(row).marginBottom };
        })()
      JS
      expect(gaps["above"]).to eq(gaps["below"])
      expect(gaps["trailing"]).to eq("0px")
    end
  end

  describe "with three or more filters" do
    before do
      create(:transfer, organization: organization)
      visit transfers_path
    end

    it "keeps the disclosure" do
      expect(page).to have_css("[data-filter-toggle]")
      expect(page).to have_no_css("main form select", visible: :visible)
    end
  end
end
