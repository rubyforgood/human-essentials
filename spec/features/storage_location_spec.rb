RSpec.feature "Barcode management", type: :feature do
  before do
    sign_in(@user)
  end
  let!(:url_prefix) { "/#{@organization.to_param}" }
  scenario "User creates a new storage location" do
    visit url_prefix + "/storage_locations/new"
    storage_location_traits = attributes_for(:storage_location)
    fill_in "Name", with: storage_location_traits[:name]
    fill_in "Address", with: storage_location_traits[:address]
    click_button "Create Storage location"

    expect(page.find(".alert")).to have_content "added"
  end

  scenario "User creates a new storage location with empty attributes" do
    visit url_prefix + "/storage_locations/new"
    click_button "Create Storage location"

    expect(page.find(".alert")).to have_content "didn't work"
  end

  scenario "User updates an existing storage location" do
    storage_location = create(:storage_location)
    visit url_prefix + "/storage_locations/#{storage_location.id}/edit"
    fill_in "Address", with: storage_location.name + " new"
    click_button "Update Storage location"

    expect(page.find(".alert")).to have_content "updated"
  end

  scenario "User updates an existing storage location with empty name" do
    storage_location = create(:storage_location)
    visit url_prefix + "/storage_locations/#{storage_location.id}/edit"
    fill_in "Name", with: ""
    click_button "Update Storage location"

    expect(page.find(".alert")).to have_content "didn't work"
  end

  scenario "User can filter the #index by those that contain certain items" do
    item = create(:item, name: "1T Diapers")
    item2 = create(:item, name: "2T Diapers")
    location1 = create(:storage_location, :with_items, item: item, item_quantity: 10, name: "Foo")
    location2 = create(:storage_location, name: "Bar")
    visit url_prefix + "/storage_locations"

    select item.name, from: "filters_containing"
    click_button "Filter"

    expect(page).to have_css("table tr", count: 2)
    expect(page).to have_xpath("//table/tbody/tr/td", text: location1.name)
    expect(page).not_to have_xpath("//table/tbody/tr/td", text: location2.name)
  end

  scenario "Filter list presented to user is in alphabetical order by item name" do
    item1 = create(:item, name: "AAA Diapers")
    item2 = create(:item, name: "ABC Diapers")
    item3 = create(:item, name: "Wonder Diapers")
    expected_order = [item1.name, item2.name, item3.name]
    storage_location1 = create(:storage_location, :with_items, item: item2, item_quantity: 10, name: "Foo")
    storage_location2 = create(:storage_location, :with_items, item: item1, item_quantity: 10, name: "Bar")
    storage_location3 = create(:storage_location, :with_items, item: item3, item_quantity: 10, name: "Baz")
    visit url_prefix + "/storage_locations"

    expect(page.all("select#filters_containing option").map(&:text).select(&:present?)).to eq(expected_order)
    expect(page.all("select#filters_containing option").map(&:text).select(&:present?)).not_to eq(expected_order.reverse)
  end

  scenario "Items in (adjustments)" do
    item = create(:item, name: "AAA Diapers")
    storage_location = create(:storage_location, :with_items,  item: item, name: "here")
    adjustment = create(:adjustment, :with_items, storage_location: storage_location)
    visit url_prefix + "/storage_locations/" + storage_location.id.to_s
    click_link "Inventory coming in"

    expect(page.find("table#sectionB.table.table-hover", visible: true)).to have_content "100"
  end

  scenario "Items out (distributions)" do
    item = create(:item, name: "AAA Diapers")
    storage_location = create(:storage_location, :with_items,  item: item, name: "here")
    adjustment = create(:adjustment, :with_items, storage_location: storage_location)
    distribution = create(:distribution, :with_items, storage_location: storage_location)
    visit url_prefix + "/storage_locations/" + storage_location.id.to_s
    click_link "Inventory coming out"

    expect(page.find("table#sectionC.table.table-hover", visible: true)).to have_content "100"
  end
end
