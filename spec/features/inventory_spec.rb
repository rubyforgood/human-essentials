RSpec.feature "Barcode management", type: :feature do
  
  scenario "User creates a new inventory" do
  	visit '/inventories/new'
  	inventory_traits = attributes_for(:inventory)
  	fill_in "Name", with: inventory_traits[:name]
  	fill_in "Address", with: inventory_traits[:address]
  	click_button "Create Inventory"

    expect(page.find('.flash.success')).to have_content "added"
  end

  scenario "User updates an existing inventory" do
  	inventory = create(:inventory)
  	visit "/inventories/#{inventory.id}/edit"
  	fill_in "Address", with: inventory.name + " new"
  	click_button "Update Inventory"

  	expect(page.find('.flash.success')).to have_content "updated"
  end

  scenario "User can filter the #index by those that contain certain items" do
    item = create(:item, name: "1T Diapers")
    item2 = create(:item, name: "2T Diapers")
    create(:inventory, :with_items, item: item, item_quantity: 10)
    create(:inventory)
    visit "/inventories"
    select item.name, from: "filters_containing"
    click_button "Filter"

    expect(page).to have_css("table#inventories tbody tr", count: 1)
  end

end
