# Where a callout sits relative to the work it qualifies. See design.md -- "Where it goes follows
# its scope".
#
# This exists because the rule has now been broken, fixed, and broken again. The new-kit warning --
# *the items in a kit are fixed once you save* -- sat below both cards at y=922 on a 720px viewport,
# 765px under the h1: you had to scroll past the thing you were composing to be told composing it
# was final. It was moved in e3e12881d, nothing pinned it, and when the working tree was rolled back
# the old placement came straight back and was reported a second time.
#
# Measured in a browser rather than asserted against markup order, because the question is where the
# reader's eye lands. A template that reads "above the first card" can still render below it once a
# wrapper moves, and the fold is a pixel count, not a position in the DOM.
RSpec.describe "Callout placement", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before { sign_in user }

  # Tops in document coordinates, so the comparison holds however tall the page is. Matched on the
  # callout's own words rather than on `[role=status]`: /kits/new carries two *empty* live regions
  # at y=0, and the first draft of this spec matched one of them and asserted nothing.
  def geometry(phrase)
    page.evaluate_script(<<~JS)
      (() => {
        const top = (el) => el ? Math.round(el.getBoundingClientRect().top + window.scrollY) : null;
        const callout = [...document.querySelectorAll("main [role]")]
          .find((el) => (el.innerText || "").includes(#{phrase.to_json}));
        return {
          h1: top(document.querySelector("h1")),
          callout: top(callout),
          found: !!callout,
          firstCard: top(document.querySelector("main .card-surface")),
          submit: top(document.querySelector("main form button[type=submit]"))
        };
      })()
    JS
  end

  describe "a warning about the whole task" do
    let(:phrase) { "fixed once you save" }

    it "sits under the page header and above the first card on /kits/new" do
      visit new_kit_path
      g = geometry(phrase)

      expect(g["found"]).to be(true), "the kit composition warning is not on the page at all"
      expect(g["callout"]).to be > g["h1"]
      expect(g["callout"]).to be < g["firstCard"],
        "the callout is below the first card (y=#{g["callout"]}, card at y=#{g["firstCard"]}) -- " \
        "a warning that arrives after the decision is not a warning"
      expect(g["callout"]).to be < g["submit"]
    end

    it "is above the fold on a 720px viewport" do
      # The number that produced the original report: y=922 on a 720px screen, which is not on it.
      page.driver.resize_window_to(page.driver.current_window_handle, 1440, 720)
      visit new_kit_path

      expect(geometry(phrase)["callout"]).to be < 720
    end
  end

  describe "a note about one section" do
    it "stays with its fields rather than moving to the top" do
      # The rule is scope, not position. This one is revealed by the checkbox above it and describes
      # the fields directly below it, so inside the card is right -- which is why the rule is stated
      # as scope and not as "callouts go at the top".
      visit new_partner_group_path
      check "Yes, send reminders"

      g = geometry("Reminders need a schedule")
      expect(g["found"]).to be(true), "the reminder note did not appear when reminders were switched on"
      expect(g["callout"]).to be > g["firstCard"],
        "a section-scoped note has drifted above the section it belongs to"
    end
  end
end
