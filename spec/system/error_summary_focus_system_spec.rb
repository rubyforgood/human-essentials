RSpec.describe "The validation error summary takes focus", type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before { sign_in(user) }

  # A failed submit re-renders the whole page -- Turbo Drive is off app-wide -- so the browser puts
  # focus back on <body> and the user is at the top of a form that looks like the one they just
  # sent. `role="alert"` does not cover this on its own: a live region is defined in terms of a
  # subtree changing, and on a full load the summary is already there when the accessibility tree
  # is first built.
  #
  # These are system specs and not request specs on purpose. The attributes are server-rendered and
  # a request spec could assert those, but *where focus ends up* is a browser fact and there is no
  # way to observe it without one.
  it "puts focus on the summary, not on the body" do
    visit new_manufacturer_path
    click_button "Save"

    # The retrying matcher first. `evaluate_script` asks once and does not wait, so reading focus
    # before the page has come back is how this passes green while proving nothing.
    expect(page).to have_css("[data-error-summary]", text: /prevented this from being saved/)

    expect(evaluate_script("document.activeElement.hasAttribute('data-error-summary')")).to be true
  end

  it "is focusable by script but is not a tab stop" do
    visit new_manufacturer_path
    click_button "Save"

    expect(page).to have_css("[data-error-summary][tabindex='-1']")
  end

  # Focusing an element that is itself `role="alert"` reads its contents twice on several screen
  # readers, so the focused container holds the live region rather than being it. The negative half
  # is the half that matters: without it, moving the role back onto the root passes the positive
  # assertion unchanged.
  it "keeps the live region inside the focused element rather than on it" do
    visit new_manufacturer_path
    click_button "Save"

    expect(page).to have_css("[data-error-summary] [role='alert']")
    expect(page).to have_no_css("[data-error-summary][role='alert']")
  end

  # design.md, "Focus is always visible": nothing takes focus without a ring, and it is the app's
  # ring rather than the browser's 1px default. A keyboard user whose focus has just been moved for
  # them is precisely who needs to see where it went.
  it "draws the design system's focus ring, not the browser's" do
    visit new_manufacturer_path
    click_button "Save"
    expect(page).to have_css("[data-error-summary]")

    outline = evaluate_script(<<~JS)
      (() => {
        const s = document.querySelector("[data-error-summary]");
        const cs = getComputedStyle(s);
        return [cs.outlineWidth, cs.outlineOffset];
      })()
    JS
    expect(outline).to eq(["2px", "2px"])
  end

  # The partner request forms use `partners/requests/_error`, a different component reaching the
  # same place through the callout's `focusable:` option.
  context "on the partner side" do
    # `authorize_verified_partners` sends anything but an approved partner back to the requests
    # index, so without this the form never renders.
    let(:partner) { create(:partner, :approved, organization: organization) }
    let(:family) { create(:partners_family, partner_id: partner.id) }
    let!(:children) { create_list(:partners_child, 2, family: family) }

    before { sign_in(partner.primary_user) }

    it "puts focus on the request error callout" do
      visit new_partners_family_request_path
      # Nothing selected, so the request is empty and the form comes back failed.
      page.all("input[type=checkbox][id^='child-']").each { |c| c.set(false) }
      # The button opens a confirmation dialog when the request is valid; with nothing selected the
      # validation runs on the server and the page comes straight back failed.
      click_button "Submit essentials request"

      expect(page).to have_css("[data-controller~='error-summary']", text: "That request could not be sent")
      expect(evaluate_script("document.activeElement.matches(\"[data-controller~='error-summary']\")")).to be true
      expect(page).to have_css("[data-controller~='error-summary'] [role='alert']")
    end
  end
end
