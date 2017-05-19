RSpec.feature "Barcode management", type: :feature do

  scenario "User creates a new storage location" do
    visit '/storage_locations/new'
    storage_location_traits = attributes_for(:storage_location)
    fill_in "Name", with: storage_location_traits[:name]
    fill_in "Address", with: storage_location_traits[:address]
    click_button "Create Storage location"

    expect(page.find('.flash.success')).to have_content "added"
  end

  scenario "User updates an existing storage location" do
    storage_location = create(:storage_location)
    visit "/storage_locations/#{storage_location.id}/edit"
    fill_in "Address", with: storage_location.name + " new"
    click_button "Update Storage location"

    expect(page.find('.flash.success')).to have_content "updated"
  end

  scenario "User can filter the #index by those that contain certain items" do
    item = create(:item, name: "1T Diapers")
    item2 = create(:item, name: "2T Diapers")
    location1 = create(:storage_location, :with_items, item: item, item_quantity: 10, name: "Foo")
    location2 = create(:storage_location, name: "Bar")
    visit "/storage_locations"

    select item.name, from: "filters_containing"
    click_button "Filter"

    expect(page).to have_css("table#storage_locations tbody tr", count: 1)
    expect(page).to have_xpath("//table[@id='storage_locations']/tbody/tr/td", text: location1.name)
    expect(page).not_to have_xpath("//table[@id='storage_locations']/tbody/tr/td", text: location2.name)
  end

end

