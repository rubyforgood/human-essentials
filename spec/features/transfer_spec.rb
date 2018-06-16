RSpec.feature "Transfer management", type: :feature do
  before do
    sign_in(@user)
  end
  let!(:url_prefix) { "/#{@organization.to_param}" }

  scenario "User can transfer an inventory from a storage location to another" do
    from_storage_location = create(:storage_location, :with_items, name: "From me", organization: @organization)
    to_storage_location = create(:storage_location, :with_items, name: "To me", organization: @organization)
    visit url_prefix + "/transfers"
    click_link "New Transfer"
    select from_storage_location.name, from: "From storage location"
    select to_storage_location.name, from: "To storage location"
    fill_in "Comment", with: "something"
    select from_storage_location.items.first.name, from: "transfer_line_items_attributes_0_item_id"
    fill_in "transfer_line_items_attributes_0_quantity", with: "10"
    click_button "Create Transfer"

    expect(page).to have_content("Transfer was successfully created")
  end

  scenario "User can filter the #index by storage location both from and to" do
    from_storage_location = create(:storage_location, name: "here", organization: @organization)
    to_storage_location = create(:storage_location, name: "there", organization: @organization)
    transfer = create(:transfer, organization: @organization, from: from_storage_location, to: to_storage_location)
    transfer2 = create(:transfer, organization: @organization, from: to_storage_location, to: from_storage_location)

    visit url_prefix + "/transfers"
    select to_storage_location.name, from: "filters_to_location"
    click_button "Filter"

    expect(page).to have_css("table tr", count: 2)

    visit url_prefix + "/transfers"
    select from_storage_location.name, from: "filters_from_location"
    click_button "Filter"

    expect(page).to have_css("table tr", count: 2)
  end
end
