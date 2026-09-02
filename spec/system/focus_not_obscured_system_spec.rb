# WCAG 2.2 · 2.4.11 Focus Not Obscured (Minimum), AA.
#
# When a control takes keyboard focus it must not be *entirely* hidden by author content. The app
# has two things that can hide one: the scroll rail, which is `position: fixed` at the bottom of the
# window whenever a table runs past the fold, and the frozen first and last table columns.
#
# Found by `bin/design/wcag22-audit.js` on five screens. The browser scrolls a newly focused element
# only far enough to touch the edge of the viewport, which is exactly where the rail sits: measured
# on `/items/quantity_and_location` at 1280x900, a focused link at y=876 height 24, with the rail at
# y=876. This pins the remedy, which is `scroll-padding`.
RSpec.describe "Focus is never scrolled under something", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:organization_admin, organization: organization) }

  before { sign_in user }

  it "reserves the scroll rail's height at the bottom of the document" do
    visit dashboard_path

    # The rail is 24px, and `scroll-padding-bottom` has to match it: too little and a focused
    # control still lands under the bar, too much and every scroll stops short for no reason.
    padding = page.evaluate_script(
      "getComputedStyle(document.documentElement).scrollPaddingBottom"
    )
    rail = page.evaluate_script(<<~JS)
      (() => {
        const probe = document.createElement("div");
        probe.className = "table-rail";
        document.body.append(probe);
        const h = getComputedStyle(probe).height;
        probe.remove();
        return h;
      })()
    JS

    expect(padding).to eq(rail)
  end

  it "reserves the frozen columns' width at each end of a scrolling table" do
    create_list(:distribution, 2, organization: organization)
    visit distributions_path
    expect(page).to have_css(".table-scroll")

    # The two widths are measured into custom properties by `table_scroll_controller` for the edge
    # shadows; the scroll padding reads the same ones, so a focused cell is never scrolled under a
    # sticky column. Asserting the *link* between them, not the pixel values, which depend on data.
    padding = page.evaluate_script(<<~JS)
      (() => {
        const region = document.querySelector(".table-scroll");
        const style = getComputedStyle(region);
        return {
          start: style.scrollPaddingInlineStart,
          end: style.scrollPaddingInlineEnd,
          pin: style.getPropertyValue("--pin-width").trim(),
          actions: style.getPropertyValue("--pin-right-width").trim()
        };
      })()
    JS

    # The actions column is frozen on every table in the app, so its width is always set and always
    # more than nothing -- if this is "0px" the custom property is not reaching the region.
    expect(padding["actions"]).to match(/\A\d+px\z/)
    expect(padding["actions"]).not_to eq("0px")
    expect(padding["end"]).to eq(padding["actions"])
    expect(padding["start"]).to eq(padding["pin"].presence || "0px")
  end
end
