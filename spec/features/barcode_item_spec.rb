RSpec.feature "Barcode management", type: :feature do
  
  scenario "User adds a new barcode" do
  	item = create(:item)
  	barcode_traits = attributes_for(:barcode_item)
  	visit '/barcode_items/new'
    select item.name, from: "Item"
    fill_in "Quantity", id: "barcode_item_quantity", with: barcode_traits[:quantity]
    fill_in "Barcode", id: "barcode_item_value", with: barcode_traits[:value]
    click_button "Create Barcode item"

    expect(page.find('.flash.success')).to have_content "added"
  end

  scenario "User updates an existing barcode" do
  	item = create(:item)
  	barcode = create(:barcode_item, item: item)
  	visit "/barcode_items/#{barcode.id}/edit"
  	fill_in "Quantity", id: "barcode_item_quantity", with: (barcode.quantity.to_i + 10).to_s
  	click_button "Update Barcode item"

  	expect(page.find('.flash.success')).to have_content "updated"
  end

end