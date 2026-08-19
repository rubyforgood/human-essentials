require "rails_helper"

# The accessibility fixes that a browser can check cheaply. The full audit lives in
# bin/design/wcag-audit.js (axe-core) and bin/design/wcag-manual.js; these are the three worth
# failing the build over, because each one was invisible until something measured it.
RSpec.describe "Accessibility", type: :system, js: true do
  let(:organization) { create(:organization) }

  describe "checkbox groups" do
    let(:partner) { create(:partner, organization: organization) }

    before do
      partner.update(status: :approved)
      login_as(partner.primary_user)
    end

    # An explicit id on the input broke the pair: f.label derives an object-prefixed `for` and the
    # input had lost the prefix, so eleven checkboxes had no label at all. Nesting the input inside
    # the label removes the coordination entirely.
    it "labels every source-of-income checkbox" do
      visit new_partners_family_path
      boxes = page.all("input[type=checkbox][name*='sources_of_income']", visible: :all)
      expect(boxes).not_to be_empty
      boxes.each do |box|
        expect(box.find(:xpath, "ancestor::label[1]")).to be_present
      end
    end
  end

  describe "in the organization settings form" do
    let(:organization_admin) { create(:organization_admin, organization: organization) }

    before do
      sign_in(organization_admin)
      visit edit_organization_path
    end

    # Trix ships 14 toolbar buttons at tabindex=-1 with no role, so headings, quotes and lists were
    # reachable by nothing at all. trix_toolbar_controller.js makes it an ARIA toolbar.
    it "the Trix toolbar is a toolbar with exactly one tab stop" do
      toolbar = page.find("trix-toolbar", match: :first)
      expect(toolbar["role"]).to eq("toolbar")
      expect(toolbar["aria-label"]).to be_present
      expect(toolbar.all("button[tabindex='0']", visible: true).size).to eq(1)
    end

    # A fieldset defaults to min-width: min-content and will not shrink, which pushed 61px of this
    # form outside a card with overflow-hidden at 320px, where it was clipped.
    it "fieldsets can shrink below their content width" do
      min_width = page.evaluate_script("getComputedStyle(document.querySelector('main fieldset')).minWidth")
      expect(min_width).to eq("0px")
    end

    # select2 defaults to width: 'resolve', which writes a pixel width once and never updates, so
    # the container outgrew its card as the viewport narrowed.
    it "select2 containers stay inside their parent" do
      overflowing = page.evaluate_script(<<~JS)
        [...document.querySelectorAll('span.select2')].filter((s) =>
          s.getBoundingClientRect().width > s.parentElement.getBoundingClientRect().width + 2).length
      JS
      expect(overflowing).to eq(0)
    end
  end
end
