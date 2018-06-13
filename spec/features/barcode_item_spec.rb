RSpec.feature "Barcode management", type: :feature do
  before do
    sign_in(@user)
  end
  let(:url_prefix) { "/#{@organization.to_param}" }

  context "While viewing the barcode items index page" do
    before do
      Item.delete_all
      create(:barcode_item, organization_id: @organization.id)
      create(:barcode_item, global: true)
      visit url_prefix + "/barcode_items"
    end

    scenario "only shows the barcodes created within the organization by default" do
      expect(page).to have_css("table#tbl_barcode_items tbody tr", count: 1)
    end

    scenario "shows all the barcodes that are viewable when 'show global' is checked" do
      check "filters_include_global"
      click_button "Filter"
      expect(page).to have_css("table#tbl_barcode_items tbody tr", count: 2)
    end
  end

  context "With organization-specific barcodes" do
    let(:barcode_traits) { attributes_for(:barcode_item, organization_id: @organization.id) }
    let(:barcode) { create(:barcode_item, organization_id: @organization.id) }

    scenario "User adds a new barcode" do
      Item.delete_all
      item = create(:item, name: "1T Diapers")
      visit url_prefix + "/barcode_items/new"
      select item.name, from: "Item"
      fill_in "Quantity", id: "barcode_item_quantity", with: barcode_traits[:quantity]
      fill_in "Barcode", id: "barcode_item_value", with: barcode_traits[:value]
      click_button "Create Barcode item"

      expect(page.find(".alert")).to have_content "added to your"

      expect(page.find("table")).to have_content "1T Diapers"

      check "filters_include_global"
      click_button "Filter"

      expect(page.find("table")).to have_content "1T Diapers"
    end

    scenario "User updates an existing barcode" do
      item = create(:item)
      barcode
      visit url_prefix + "/barcode_items/#{barcode.id}/edit"
      fill_in "Quantity", id: "barcode_item_quantity", with: (barcode.quantity.to_i + 10).to_s
      click_button "Update Barcode item"

      expect(page.find(".alert")).to have_content "updated"
    end

    scenario "User updates an existing barcode with empty attributes" do
      barcode
      visit url_prefix + "/barcode_items/#{barcode.id}/edit"
      fill_in "Quantity", id: "barcode_item_quantity", with: ""
      click_button "Update Barcode item"

      expect(page.find(".alert")).to have_content "didn't work"
    end
  end

  context "With global barcodes" do
    let(:barcode_traits) { attributes_for(:global_barcode_item) }
    let(:barcode) { create(:global_barcode_item) }

    scenario "User adds a new barcode to the global pool" do
      Item.delete_all
      item = create(:item, name: "1T Diapers")
      visit url_prefix + "/barcode_items/new"
      select item.name, from: "Item"
      fill_in "Quantity", id: "barcode_item_quantity", with: barcode_traits[:quantity]
      fill_in "Barcode", id: "barcode_item_value", with: barcode_traits[:value]
      expect(page).to have_xpath("//input[@id='barcode_item_global_true']")
      choose "barcode_item_global_true"
      click_button "Create Barcode item"

      expect(page.find(".alert")).to have_content "added globally"

      expect(page.find("table")).to_not have_content "1T Diapers"

      check "filters_include_global"
      click_button "Filter"

      expect(page.find("table")).to have_content "1T Diapers"
    end
  end

  scenario "User can filter the #index by item type" do
    Item.delete_all
    item = create(:item, name: "1T Diapers")
    item2 = create(:item, name: "2T Diapers")
    create(:barcode_item, organization: @organization, barcodeable: item)
    create(:barcode_item, organization: @organization, barcodeable: item2)
    visit url_prefix + "/barcode_items"
    select item.name, from: "filters_barcodeable_id"
    click_button "Filter"

    expect(page).to have_css("table tbody tr", count: 1)
  end

  scenario "Filter presented to user lists items in alphabetical order" do
    item1 = create(:item, name: "AAA Diapers")
    item2 = create(:item, name: "Wonder Diapers")
    item3 = create(:item, name: "ABC Diapers")
    expected_order = ["", item1.name, item3.name, item2.name]

    create(:barcode_item, barcodeable: item3)
    create(:barcode_item, barcodeable: item2)
    create(:barcode_item, barcodeable: item1)
    visit url_prefix + "/barcode_items"

    expect(page.all("select#filters_barcodeable_id option").map(&:text)).to eq(expected_order)
    expect(page.all("select#filters_barcodeable_id option").map(&:text)).not_to eq(expected_order.reverse)
  end

  scenario "User add a new barcode with empty attributes" do
    visit url_prefix + "/barcode_items/new"
    click_button "Create Barcode item"

    expect(page.find(".alert")).to have_content "didn't work"
  end
end
