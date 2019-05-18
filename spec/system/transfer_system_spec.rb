RSpec.describe "Transfer management", type: :system do
  before do
    sign_in(@user)
  end
  let!(:url_prefix) { "/#{@organization.to_param}" }

  it "can transfer an inventory from a storage location to another as a user" do
    from_storage_location = create(:storage_location, :with_items, name: "From me", organization: @organization)
    to_storage_location = create(:storage_location, :with_items, name: "To me", organization: @organization)
    visit url_prefix + "/transfers"
    click_link "New Transfer"
    within "form#new_transfer" do
      select from_storage_location.name, from: "From storage location"
      select to_storage_location.name, from: "To storage location"
      fill_in "Comment", with: "something"
      select from_storage_location.items.first.name, from: "transfer_line_items_attributes_0_item_id"
      fill_in "transfer_line_items_attributes_0_quantity", with: "10"
      click_on "Save"
    end
    expect(page).to have_content("10 items have been transferred")
  end

  context "when there's insufficient inventory at the origin to cover the move" do
    let!(:from_storage_location) { create(:storage_location, :with_items, item_quantity: 10, name: "From me", organization: @organization) }
    let!(:to_storage_location) { create(:storage_location, :with_items, name: "To me", organization: @organization) }

    scenario "User can transfer an inventory from a storage location to another" do
      visit url_prefix + "/transfers"
      click_link "New Transfer"
      within "form#new_transfer" do
        select from_storage_location.name, from: "From storage location"
        select to_storage_location.name, from: "To storage location"
        fill_in "Comment", with: "something"
        select from_storage_location.items.first.name, from: "transfer_line_items_attributes_0_item_id"
        fill_in "transfer_line_items_attributes_0_quantity", with: "100"
        click_on "Save"
      end
      expect(page).to have_content("exceed the available inventory")
    end
  end

  it "can filter the #index by storage location both from and to as a user" do
    from_storage_location = create(:storage_location, name: "here", organization: @organization)
    to_storage_location = create(:storage_location, name: "there", organization: @organization)
    create(:transfer, organization: @organization, from: from_storage_location, to: to_storage_location)
    create(:transfer, organization: @organization, from: to_storage_location, to: from_storage_location)

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
