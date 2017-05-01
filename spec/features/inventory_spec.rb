RSpec.feature "Barcode management", type: :feature do
  
  scenario "User creates a new inventory" do
  	visit '/inventories/new'
  	inventory_traits = attributes_for(:inventory)
  	fill_in "Name", with: inventory_traits[:name]
  	fill_in "Address", with: inventory_traits[:address]
  	click_button "Create Inventory"

    expect(page.find('.flash.success')).to have_content "added"
  end

  scenario "User updates an existing barcode" do
  	inventory = create(:inventory)
  	visit "/inventories/#{inventory.id}/edit"
  	fill_in "Address", with: inventory.name + " new"
  	click_button "Update Inventory"

  	expect(page.find('.flash.success')).to have_content "updated"
  end

end
