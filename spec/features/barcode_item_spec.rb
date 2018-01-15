RSpec.feature "Barcode management", type: :feature do
  before do
    sign_in(@user)
  end

  scenario "The barcode index only shows the barcodes created within the organization" do
    item = create(:item, name: "1T Diapers")
    item2 = create(:item, name: "2T Diapers")
    create(:barcode_item, :for_organization, organization_id: @organization.id, item: Item.first)
    create(:barcode_item, item: Item.last)
    visit "/#{@organization.short_name}/barcode_items"
    expect(page).to have_css("table tr", count: 2)
  end

  context "With organization-specific barcodes" do
    let(:barcode_traits) { attributes_for(:barcode_item, :for_organization, organization_id: @organization.id) }
    let(:barcode) { create(:barcode_item, :for_organization, organization_id: @organization.id) }

    scenario "User adds a new barcode" do
      item = create(:item)
      visit "/#{@organization.short_name}/barcode_items/new"
      select item.name, from: "Item"
      fill_in "Quantity", id: "barcode_item_quantity", with: barcode_traits[:quantity]
      fill_in "Barcode", id: "barcode_item_value", with: barcode_traits[:value]
      uncheck 'barcode_item_global'
      click_button "Create Barcode item"

      expect(page.find('.alert')).to have_content "added to your"
    end

    scenario "User updates an existing barcode" do
      item = create(:item)
      barcode
      visit "/#{@organization.short_name}/barcode_items/#{barcode.id}/edit"
      fill_in "Quantity", id: "barcode_item_quantity", with: (barcode.quantity.to_i + 10).to_s
      click_button "Update Barcode item"

      expect(page.find('.alert')).to have_content "updated"
    end
  end

  context "With global barcodes" do
    let(:barcode_traits) { attributes_for(:barcode_item, organization_id: nil) }
    let(:barcode) { create(:barcode_item, organization_id: nil) }

    scenario "User adds a new barcode to the global pool" do
      item = create(:item)
      visit "/#{@organization.short_name}/barcode_items/new"
      select item.name, from: "Item"
      fill_in "Quantity", id: "barcode_item_quantity", with: barcode_traits[:quantity]
      fill_in "Barcode", id: "barcode_item_value", with: barcode_traits[:value]
      expect(page).to have_xpath("//input[@id='barcode_item_global']")
      check "barcode_item_global"
      click_button "Create Barcode item"

      expect(page.find('.alert')).to have_content "added globally"
    end
  end


  scenario "User can filter the #index by item type" do
    item = create(:item, name: "1T Diapers")
    item2 = create(:item, name: "2T Diapers")
    create(:barcode_item, :for_organization, organization_id: @organization.id, item: Item.first)
    create(:barcode_item, :for_organization, organization_id: @organization.id, item: Item.last)
    visit "/#{@organization.short_name}/barcode_items"
    select Item.first.name, from: "filters_item_id"
    click_button "Filter"

    expect(page).to have_css("table tr", count: 2)
  end

  scenario "Filter presented to user lists items in alphabetical order" do
    item1 = create(:item, name: "AAA Diapers")
    item2 = create(:item, name: "Wonder Diapers")
    item3 = create(:item, name: "ABC Diapers")
    expected_order = ['', item1.name, item3.name, item2.name]

    create(:barcode_item, item: item3)
    create(:barcode_item, item: item2)
    create(:barcode_item, item: item1)
    visit "/#{@organization.short_name}/barcode_items"

    expect(page.all('select#filters_item_id option').map(&:text)).to eq(expected_order)
    expect(page.all('select#filters_item_id option').map(&:text)).not_to eq(expected_order.reverse)
  end
end
