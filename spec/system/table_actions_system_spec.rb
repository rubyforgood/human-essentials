RSpec.describe "Table actions", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  before { sign_in(organization_admin) }

  # Four variants existed across 43 tables: 33 hidden and plural, 8 visible, one `<th>Action` with
  # no scope and no alignment, one hidden and singular.
  describe "the actions column header" do
    # A row each, or the page renders its empty state and there is no table to check.
    before do
      create(:item, organization: organization)
      create(:partner, organization: organization)
      create(:donation_site, organization: organization)
      create(:vendor, organization: organization)
    end

    it "is visible, scoped and right-aligned on every table" do
      %w[/items /partners /donation_sites /vendors].each do |path|
        visit path
        header = page.evaluate_script(<<~JS)
          (() => {
            const ths = [...document.querySelectorAll("table.data-table thead th")];
            const last = ths[ths.length - 1];
            return { text: last.textContent.trim(), scope: last.getAttribute("scope"),
                     align: getComputedStyle(last).textAlign,
                     srOnly: !!last.querySelector(".sr-only") };
          })()
        JS
        expect(header["text"]).to eq("Actions"), "#{path} header is #{header["text"].inspect}"
        expect(header["scope"]).to eq("col"), "#{path} header has no scope"
        expect(header["align"]).to eq("right")
        expect(header["srOnly"]).to be(false), "#{path} still hides its header"
      end
    end
  end

  # An action that cannot succeed is still offered: the server checks and answers with the reason
  # and the next step. A disabled item had room for a phrase; a flash has room for what to do.
  describe "an action that cannot succeed" do
    let!(:item) { create(:item, organization: organization, name: "Held item") }

    before do
      TestInventory.create_inventory(organization,
        create(:storage_location, organization: organization).id => [[item.id, 5]])
      visit items_path
    end

    it "is offered, and explains itself when it fails" do
      menu = open_row_menu(row: "Held item")
      expect(menu).to have_button("Deactivate", disabled: false)

      accept_confirm_dialog { menu.click_on "Deactivate" }

      expect(page).to have_content("Held item still has stock in a storage location")
      expect(page).to have_content("Move or distribute the remaining stock")
      expect(item.reload).to be_active
    end
  end

  # The confirmation is the app's own <dialog>, not window.confirm -- which is browser chrome, and
  # the one overlay no DOM audit can see.
  describe "the confirmation" do
    let!(:vendor) { create(:vendor, organization: organization, business_name: "Acme Supplies") }

    before { visit vendors_path }

    # A vendor with no purchases offers Delete, which is also the destructive tone.
    it "is the design system's dialog, and cancelling does nothing" do
      click_row_action "Delete", row: "Acme Supplies"

      dialog = page.document.find("dialog[open]")
      expect(dialog).to have_text("Acme Supplies")
      expect(dialog).to have_button("Cancel")

      dialog.find("button", text: "Cancel").click
      expect(page.document).to have_no_css("dialog[open]")
      expect(Vendor.where(id: vendor.id)).to exist
    end

    it "names the action on its confirm button and reddens a destructive one" do
      click_row_action "Delete", row: "Acme Supplies"

      accept = page.document.find("dialog[open] [data-confirm-dialog-target='accept']")
      expect(accept.text).to eq("Delete")
      # rose-600, the danger variant -- not the indigo a harmless action gets.
      expect(accept[:class]).to include("bg-rose-600")
    end
  end
end
