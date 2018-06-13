RSpec.feature "Adjustment management", type: :feature do
  before do
    sign_in(@user)
  end
  let!(:url_prefix) { "/#{@organization.to_param}" }

  scenario "User can add an inventory adjustment at a storage location", js: true do
    add_quantity = 10
    storage_location = create(:storage_location, :with_items, organization: @organization)
    visit url_prefix + "/adjustments"
    click_link "New Adjustment"
    select storage_location.name, from: "From storage location"
    fill_in "Comment", with: "something"
    select Item.last.name, from: "adjustment_line_items_attributes_0_item_id"
    fill_in "adjustment_line_items_attributes_0_quantity", with: add_quantity.to_s

    expect do
      click_button "Create Adjustment"
    end.to change { storage_location.size }.by(add_quantity)
    expect(page).to have_content("Adjustment was successfully created")
  end

  scenario "User can subtract an inventory adjustment at a storage location", js: true do
    sub_quantity = -10
    storage_location = create(:storage_location, :with_items, organization: @organization)
    visit url_prefix + "/adjustments"
    click_link "New Adjustment"
    select storage_location.name, from: "From storage location"
    fill_in "Comment", with: "something"
    select Item.last.name, from: "adjustment_line_items_attributes_0_item_id"
    fill_in "adjustment_line_items_attributes_0_quantity", with: sub_quantity.to_s

    expect do
      click_button "Create Adjustment"
    end.to change { storage_location.size }.by(sub_quantity)
    expect(page).to have_content("Adjustment was successfully created")
  end

  scenario "User can filter the #index by storage location" do
    storage_location = create(:storage_location, name: "here", organization: @organization)
    storage_location2 = create(:storage_location, name: "there", organization: @organization)
    adjustment = create(:adjustment, organization: @organization, storage_location: storage_location)
    adjustment2 = create(:adjustment, organization: @organization, storage_location: storage_location2)

    visit url_prefix + "/adjustments"
    select storage_location.name, from: "filters_at_location"
    click_button "Filter"

    expect(page).to have_css("table tr", count: 2)
  end
end
