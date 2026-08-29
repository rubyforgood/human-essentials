RSpec.describe "Barcode management", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }
  let(:base_item) { create(:base_item) }

  before do
    sign_in(user)
  end

  context "While viewing the barcode items index page" do
    subject { barcode_items_path }

    before do
      Item.delete_all
    end

    it "should only show the barcodes created within the organization" do
      create(:barcode_item, organization_id: organization.id)
      create(:global_barcode_item)
      visit subject
      expect(page).to have_css("table tbody tr", count: 1)
    end

    it "can have a user filter the #index by barcode value" do
      b = create(:barcode_item, organization: organization)
      create(:barcode_item, organization: organization)
      visit subject
      open_filters
      fill_in "filters[by_value]", with: b.value
      wait_for_filters

      expect(page).to have_css("table tbody tr", count: 1)
    end

    it "should have the filter presented to user list items in alphabetical order" do
      item1 = create(:item, name: "AAA Diapers")
      item2 = create(:item, name: "Wonder Diapers")
      item3 = create(:item, name: "ABC Diapers")
      expected_order = ["", item1.name, item3.name, item2.name]

      create(:barcode_item, barcodeable: item3)
      create(:barcode_item, barcodeable: item2)
      create(:barcode_item, barcodeable: item1)
      visit subject

      open_filters
      expect(page.all('select[name="filters[barcodeable_id]"] option').map(&:text)).to eq(expected_order)
      expect(page.all('select[name="filters[barcodeable_id]"] option').map(&:text)).not_to eq(expected_order.reverse)
    end

    it "can have a user filter the #index by item type" do
      b = create(:barcode_item, organization: organization)
      create(:barcode_item, organization: organization)
      visit subject
      open_filters
      select b.item.name, from: "filters[barcodeable_id]"
      wait_for_filters

      expect(page).to have_css("table tbody tr", count: 1)
    end

    it "can have a user filter the #index by base item type" do
      item = create(:item, name: "Red 1T Diapers", base_item: base_item)
      item2 = create(:item, name: "Blue 1T Diapers", base_item: base_item)
      create(:barcode_item, organization: organization, barcodeable: item)
      create(:barcode_item, organization: organization, barcodeable: item2)

      visit subject
      open_filters
      select BaseItem.first.name, from: "filters[by_item_partner_key]"
      wait_for_filters

      expect(page).to have_css("table tbody tr", count: 2)
    end

    it "can delete a barcode item" do
      item = create(:item, name: "Red 1T Diapers", base_item: base_item)
      create(:barcode_item, organization: organization, barcodeable: item, value: "barcode_to_delete")

      visit subject
      expect(page).to have_content("barcode_to_delete")
      accept_confirm_dialog { click_button "Delete" }
      expect(page).to have_content("Barcode deleted!")
      expect(page).not_to have_content("barcode_to_delete")
    end

    it "Double clicking the delete button does not result in the barcode attemping to be deleted twice" do
      item = create(:item, name: "Red 1T Diapers", base_item: base_item)
      b_item = create(:barcode_item, organization: organization, barcodeable: item, value: "barcode_to_delete")

      visit subject
      expect(page).to have_content(b_item.value)
      # The delete goes through the confirmation dialog now, so the double click that matters is
      # on its confirm button -- clicking Delete twice just opens the dialog.
      click_button "Delete"
      ferrum_double_click("dialog[open] [data-confirm-dialog-target='accept']")
      expect(page).to have_content("Barcode deleted!")
      expect(page).not_to have_content("barcode_to_delete")
      expect(page).not_to have_content("Sorry, you don't have permission to delete this barcode.")
    end
  end

  context "With organization-specific barcodes" do
    let(:barcode_traits) { attributes_for(:barcode_item, organization_id: organization.id) }

    it "can have a user add a new barcode" do
      Item.delete_all
      item = create(:item, name: "1T Diapers")
      visit new_barcode_item_path
      open_filters
      select item.name, from: "Item"
      fill_in "Quantity", id: "barcode_item_quantity", with: barcode_traits[:quantity]
      fill_in "Barcode", id: "barcode_item_value", with: barcode_traits[:value]
      click_button "Save"

      expect(page.find("[data-flash]")).to have_content "added to your"

      expect(page.find("table")).to have_content "1T Diapers"

      # There is no Filter button to press any more -- the bar applies on change. Reloading the
      # index is the round trip this was checking: that the new barcode is really in the list
      # and not just in the page the create action rendered.
      visit barcode_items_path

      expect(page.find("table")).to have_content "1T Diapers"
    end

    context "when editing an existing barcode" do
      subject { edit_barcode_item_path(barcode.id) }
      let!(:barcode) { create(:barcode_item, organization_id: organization.id) }

      it "saves the changes if they are valid" do
        create(:item)
        visit subject
        fill_in "Quantity", id: "barcode_item_quantity", with: (barcode.quantity.to_i + 10).to_s
        click_button "Save"

        expect(page.find("[data-flash]")).to have_content "updated"
      end

      it "fails to save the changes if the attributes are empty" do
        visit subject
        fill_in "Quantity", id: "barcode_item_quantity", with: ""
        click_button "Save"

        expect(page).to have_css("[data-error-summary]", text: /prevented this from being saved/)
      end
    end
  end

  it "prevents a user from adding a new barcode with empty attributes" do
    visit new_barcode_item_path
    click_button "Save"

    expect(page).to have_css("[data-error-summary]", text: /prevented this from being saved/)
  end

  # The camera scanner existed -- `utils/barcode_scan` is imported on every page and quagga is
  # pinned -- and the form for *creating* a barcode was the one place it was missing, so the only
  # way to enter a barcode there was to read it off the box and type it.
  #
  # This asserts the region the scanner needs rather than driving the camera: `barcode_scan.js`
  # finds its input and its viewport through `[data-barcode-scan]`, and a button outside one is a
  # button that does nothing.
  describe "the camera scanner on the barcode form" do
    it "gives the barcode field a scan button wired to a viewport" do
      visit new_barcode_item_path

      region = find("[data-barcode-scan]")
      expect(region).to have_css("button.barcode-scanner[aria-label='Scan a barcode with the camera']")
      expect(region).to have_css("i.bi-upc-scan", visible: :all)

      # The three parts the scanner joins up, all inside one region.
      wiring = page.evaluate_script(<<~JS)
        (() => {
          const r = document.querySelector("[data-barcode-scan]");
          return { input: r.querySelector("input:not([type=hidden])")?.name,
                   viewport: !!r.querySelector("[data-barcode-viewport]"),
                   hiddenAtRest: r.querySelector("[data-barcode-viewport]").classList.contains("hidden"),
                   expanded: r.querySelector("button.barcode-scanner").getAttribute("aria-expanded") };
        })()
      JS
      expect(wiring["input"]).to eq("barcode_item[value]")
      expect(wiring["viewport"]).to be true
      expect(wiring["hiddenAtRest"]).to be true
      expect(wiring["expanded"]).to eq("false")
    end

    # No id on the button. Three partials once carried `id="barcode-scanner-btn"`, and a donation
    # form renders two of them, so the camera drew itself into whichever came first.
    it "identifies the scanner by region rather than by id" do
      visit new_barcode_item_path
      expect(page).to have_no_css("#barcode-scanner-btn")
    end
  end
end
