RSpec.feature "Item management", type: :feature do
  before do
    sign_in(@user)
  end
  let!(:url_prefix) { "/#{@organization.to_param}" }
  scenario "User creates a new item" do
    visit url_prefix + "/items/new"
    item_traits = attributes_for(:item)
    fill_in "Name", with: item_traits[:name]
    fill_in "Category", with: item_traits[:category]
    select CanonicalItem.last.name, from: "Base Item"
    click_button "Create Item"

    expect(page.find(".alert")).to have_content "added"
  end

  scenario "User creates a new item with empty attributes" do
    visit url_prefix + "/items/new"
    item_traits = attributes_for(:item)
    click_button "Create Item"

    expect(page.find(".alert")).to have_content "didn't work"
  end

  scenario "User updates an existing item" do
    item = create(:item)
    visit url_prefix + "/items/#{item.id}/edit"
    fill_in "Category", with: item.category + " new"
    click_button "Update Item"

    expect(page.find(".alert")).to have_content "updated"
  end

  scenario "User updates an existing item with empty attributes" do
    item = create(:item)
    visit url_prefix + "/items/#{item.id}/edit"
    fill_in "Name", with: ""
    click_button "Update Item"

    expect(page.find(".alert")).to have_content "didn't work"
  end

  scenario "User can filter the #index by category type" do
    Item.delete_all
    item = create(:item, category: "same")
    item2 = create(:item, category: "different")
    visit url_prefix + "/items"
    select Item.first.category, from: "filters_in_category"
    click_button "Filter"

    expect(page).to have_css("table tbody tr", count: 3)
  end

  scenario "User can filter the #index by canonical item" do
    Item.delete_all
    item = create(:item, canonical_item: CanonicalItem.first)
    item2 = create(:item, canonical_item: CanonicalItem.last)
    visit url_prefix + "/items"
    select CanonicalItem.first.name, from: "filters_by_canonical_item"
    click_button "Filter"
    within "#tbl_items" do
      expect(page).to have_css("tbody tr", count: 1)
    end
  end

  scenario "Filters presented to user are alphabetized by category" do
    Item.delete_all
    item = create(:item, category: "same")
    item2 = create(:item, category: "different")
    expected_order = [item2.category, item.category]
    visit url_prefix + "/items"

    expect(page.all("select#filters_in_category option").map(&:text).select(&:present?)).to eq(expected_order)
    expect(page.all("select#filters_in_category option").map(&:text).select(&:present?)).not_to eq(expected_order.reverse)
  end

  describe "Item Table Tabs >" do
    let(:item_name_1) { "the most wonderful magical pullups that truly potty train" }
    let(:item_name_2) { "blackbeard's rugged tampons" }
    before :each do
      @item = create(:item, name: item_name_1, category: "same")
      @item2 = create(:item, name: item_name_2, category: "different")
      @storage = create(:storage_location, :with_items, item: @item, item_quantity: 666, name: "Test storage")
      visit url_prefix + "/items"
    end
    # Consolidated these into one to reduce the setup/teardown
    scenario "Displays items in separate tabs", js: true do
      expect(page.find("table#tbl_items", visible: true)).not_to have_content "Quantity"
      expect(page.find(:css, "table#tbl_items", visible: true)).to have_content(@item.name)
      expect(page.body).to include(item_name_1)
      expect(page.body).to include(item_name_2)

      click_link "Items and Quantity" # href="#sectionB"
      expect(page.find("table#tbl_items_quantity", visible: true)).to have_content "Quantity"
      expect(page.find("table#tbl_items_quantity", visible: true)).not_to have_content "Test storage"
      expect(page.find("table#tbl_items_quantity", visible: true)).to have_content "666"
      expect(page.body).to include(item_name_1)
      expect(page.body).to include(item_name_2)

      click_link "Items, Quantity, and Location" # href="#sectionC"
      expect(page.find("table#tbl_items_location", visible: true)).to have_content "Quantity"
      expect(page.find("table#tbl_items_location", visible: true)).to have_content "Test storage"
      expect(page.find("table#tbl_items_location", visible: true)).to have_content "666"
      expect(page.body).to include(item_name_1)
      expect(page.body).to include(item_name_2)
    end
  end
end
