  RSpec.feature "Item management", type: :feature do
  before do
    sign_in(@user)
  end
  let!(:url_prefix) { "/#{@organization.to_param}" }
  scenario "User creates a new item" do
    visit url_prefix + '/items/new'
    item_traits = attributes_for(:item)
    fill_in "Name", with: item_traits[:name]
    fill_in "Category", with: item_traits[:category]
    click_button "Create Item"

    expect(page.find('.flash.success')).to have_content "added"
  end

  scenario "User updates an existing item" do
    item = create(:item)
    visit url_prefix + "/items/#{item.id}/edit"
    fill_in "Category", with: item.category + " new"
    click_button "Update Item"

    expect(page.find('.flash.success')).to have_content "updated"
  end

  scenario "User can filter the #index by category type" do
    Item.delete_all
    item = create(:item, category: "same")
    item2 = create(:item, category: "different")
    visit url_prefix + "/items"
    select Item.first.category, from: "filters_in_category"
    click_button "Filter"

    expect(page).to have_css("table tbody tr", count: 1)
  end

  scenario "Filters presented to user are alphabetized by category" do
    Item.delete_all
    item = create(:item, category: "same")
    item2 = create(:item, category: "different")
    expected_order = ["", item2.category, item.category]
    visit url_prefix + "/items"

    expect(page.all('select#filters_in_category option').map(&:text)).to eq(expected_order)
    expect(page.all('select#filters_in_category option').map(&:text)).not_to eq(expected_order.reverse)
  end

  scenario "Filter show items without quantity" do
  Item.delete_all
  item = create(:item, category: "same")
  item2 = create(:item, category: "different")
  storage = create(:storage_location, name: "Test storage")
  visit url_prefix + "/items"
  choose('filters_show_quantity_0')
  click_button "Filter"
  expect(page.find('table#items')).not_to have_content "Quantity"
  end

  scenario "Filter show items without quantity (without choosing radio button)" do
    Item.delete_all
    item = create(:item, category: "same")
    item2 = create(:item, category: "different")
    storage = create(:storage_location, name: "Test storage")
    visit url_prefix + "/items"
    click_button "Filter"
    expect(page.find('table#items')).not_to have_content "Quantity"
    page.should have_selector('table#items tr', :count => 3)
  end

  scenario "Filter show items with quantity and without storage" do
    Item.delete_all
    InventoryItem.delete_all
    StorageLocation.delete_all
    item = create(:item, category: "same", id: 1)
    item2 = create(:item, category: "different", id: 2)
    storage = create(:storage_location, name: "Test storage", id: 1)
    inventory_item = create(:inventory_item, storage_location_id: 1, item_id: 1, quantity: 666)
    visit url_prefix + "/items"
    choose('filters_show_quantity_1')
    click_button "Filter"
    expect(page.find('table#items')).to have_content "Quantity"
    expect(page.find('table#items')).not_to have_content "Test storage"
    expect(page.find('table#items')).to have_content "666"
    page.should have_selector('table#items tr', :count => 3)
  end

  scenario "Filter show items with quantity and storage" do
    Item.delete_all
    InventoryItem.delete_all
    StorageLocation.delete_all
    item = create(:item, category: "same", id: 1)
    item2 = create(:item, category: "different", id: 2)
    storage = create(:storage_location, name: "Test storage", id: 1)
    inventory_item = create(:inventory_item, storage_location_id: 1, item_id: 1, quantity: 666)
    visit url_prefix + "/items"
    choose('filters_show_quantity_2')
    click_button "Filter"
    expect(page.find('table#items')).to have_content "Quantity"
    expect(page.find('table#items')).to have_content "Test storage"
    expect(page.find('table#items')).to have_content "666"
    page.should have_selector('table#items tr', :count => 3)
  end
end
