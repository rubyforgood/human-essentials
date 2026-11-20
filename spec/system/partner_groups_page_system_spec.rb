require "rails_helper"

# The Groups tab used to switch a panel in place, which meant the page's primary action could
# not follow it -- "New partner group" ended up in a bar of its own above the table. The tabs
# navigate now, so each has its own URL and its own primary action.
RSpec.describe "Partner groups page", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before { sign_in(user) }

  it "gives each tab its own URL" do
    visit partners_path
    expect(page).to have_css('nav[aria-label="Sections"] a[aria-current="page"]', text: "Partners")

    click_on "Groups"
    expect(page).to have_current_path(partner_groups_path)
    expect(page).to have_css('nav[aria-label="Sections"] a[aria-current="page"]', text: "Groups")

    click_on "Partners"
    expect(page).to have_current_path(partners_path)
  end

  it "swaps the primary action with the tab" do
    visit partners_path
    expect(page).to have_link("New partner agency")
    expect(page).to have_no_link("New partner group")

    click_on "Groups"
    expect(page).to have_link("New partner group")
    expect(page).to have_no_link("New partner agency")
  end

  it "keeps the header to three actions, exactly one of them primary" do
    visit partners_path
    actions = find('[data-page-header="actions"]')
    buttons = actions.all("a,button")
    expect(buttons.size).to be <= 3

    # The variant survives either in the class the old helper emitted directly, or -- for
    # essentials_link_button, which now renders through <rfg-button> (vendor/javascript/rfg-button.js,
    # see designsystem's ADR 14) -- as a real attribute on the host, since the rendered control no
    # longer carries a Tailwind utility class at all. Same fix as bin/design/button-audit.js's
    # own variantOf, for the same reason.
    primaries = page.evaluate_script(<<~JS)
      [...document.querySelectorAll('[data-page-header="actions"] a, [data-page-header="actions"] button')]
        .filter((el) => {
          if (el.className.includes("bg-brand-600")) return true;
          const host = el.closest("rfg-button");
          return host ? (host.getAttribute("variant") || "primary") === "primary" : false;
        }).length
    JS
    expect(primaries).to eq(1)
  end

  it "does not announce the links as a tablist" do
    # role="tab" promises a panel swaps in this document. These load a page.
    visit partner_groups_path
    expect(page).to have_no_css('[role="tablist"]')
    expect(page).to have_no_css('[role="tab"]')
  end

  it "lists the groups" do
    create(:partner_group, organization: organization, name: "Shelters")
    visit partner_groups_path
    expect(page).to have_css("table", text: "Shelters")
  end
end
