RSpec.describe "Custom request units", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  before do
    Flipper.enable(:enable_packs)
    organization.request_units.create!(name: "pack")
    organization.request_units.create!(name: "box")
    sign_in(organization_admin)
    visit edit_organization_path
  end

  after { Flipper.disable(:enable_packs) }

  # Capybara does not match `aria-label` unless `enable_aria_label` is on, and it is not --
  # `distribution_system_spec.rb` carries the same workaround. The button's whole content is an
  # icon, so its name lives there.
  def remove_unit(name)
    find("button[aria-label='Remove #{name}']").click
  end

  def submitted_units
    page.evaluate_script(<<~JS)
      [...document.querySelectorAll('[data-controller="tag-input"] select option')]
        .filter(o => o.selected).map(o => o.value)
    JS
  end

  it "shows the saved units as chips" do
    expect(page).to have_css("[data-tag-input-target='chips'] span", count: 2)
    expect(submitted_units).to contain_exactly("pack", "box")
  end

  # The whole point of the rebuild: select2 hid its dropdown, so the control looked like a select,
  # opened nothing, and never said the interaction was "type, then comma".
  it "says what to do, and adds a unit on Enter" do
    expect(page).to have_content("Type a unit and press Enter")
    fill_in "Custom request units", with: "carton"
    find("#organization_request_unit_names_input").send_keys(:enter)
    expect(page).to have_css("[data-tag-input-target='chips'] span", count: 3)
    expect(submitted_units).to include("carton")
  end

  # Comma and Tab were select2's separators. Anyone with the habit keeps it.
  it "still accepts a comma as a separator" do
    fill_in "Custom request units", with: "bale,"
    expect(page).to have_css("[data-tag-input-target='chips'] span", count: 3)
    expect(submitted_units).to include("bale")
  end

  it "refuses a duplicate whatever its case" do
    fill_in "Custom request units", with: "PACK"
    find("#organization_request_unit_names_input").send_keys(:enter)
    expect(page).to have_css("[data-tag-input-target='chips'] span", count: 2)
    expect(submitted_units).to contain_exactly("pack", "box")
  end

  it "removes a unit from its chip" do
    remove_unit("pack")
    expect(page).to have_css("[data-tag-input-target='chips'] span", count: 1)
    expect(submitted_units).to contain_exactly("box")
  end

  it "saves what the chips say" do
    fill_in "Custom request units", with: "carton"
    find("#organization_request_unit_names_input").send_keys(:enter)
    remove_unit("pack")
    click_on "Save"

    expect(page).to have_content("Updated your organization!")
    expect(organization.reload.request_units.pluck(:name)).to contain_exactly("box", "carton")
  end

  # The <select multiple> is the field; the chips are a view of it. Hiding it is gated on the
  # controller having run, the same way the table rail gates hiding the native scrollbar.
  it "keeps the native select as the thing that submits" do
    select_state = page.evaluate_script(<<~JS)
      (() => {
        const wrap = document.querySelector('[data-controller="tag-input"]');
        const sel = wrap.querySelector("select");
        return { ready: wrap.dataset.tagInput, name: sel.name,
                 hidden: getComputedStyle(sel).display === "none" };
      })()
    JS
    expect(select_state["name"]).to eq("organization[request_unit_names][]")
    expect(select_state["ready"]).to eq("ready")
    expect(select_state["hidden"]).to be true
  end

  # select2's remove control measured 9x21 against WCAG 2.5.8's 24x24.
  it "gives the remove control a 24px target" do
    size = page.evaluate_script(<<~JS)
      (() => {
        const b = document.querySelector("[data-tag-input-target='chips'] button");
        const r = b.getBoundingClientRect();
        return { w: Math.round(r.width), h: Math.round(r.height) };
      })()
    JS
    expect(size["w"]).to be >= 24
    expect(size["h"]).to be >= 24
  end
end
