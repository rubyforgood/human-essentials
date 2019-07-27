# TODO: Can this be deleted?
RSpec.feature "Item management", type: :feature do
  before do
    sign_in(@user)
  end
  let!(:url_prefix) { "/#{@organization.to_param}" }
  scenario "User creates a new item" do
    visit url_prefix + "/items/new"
    item_traits = attributes_for(:item)
    fill_in "Name", with: item_traits[:name]
    select BaseItem.last.name, from: "Base Item"
    click_button "Save"

    expect(page.find(".alert")).to have_content "added"
  end

  scenario "User creates a new item with empty attributes" do
    visit url_prefix + "/items/new"
    click_button "Save"

    expect(page.find(".alert")).to have_content "didn't work"
  end

  scenario "User updates an existing item" do
    item = create(:item)
    visit url_prefix + "/items/#{item.id}/edit"
    click_button "Save"

    expect(page.find(".alert")).to have_content "updated"
  end

  scenario "User sets a distribution quantity and package size" do
    item = create(:item)
    visit url_prefix + "/items/#{item.id}/edit"
    fill_in "item_distribution_quantity", with: "75"
    fill_in "item_package_size", with: "50"
    click_button "Save"

    find("[data-item-id=#{item.id}] [href$=edit]").click

    expect(page).to have_selector("input#item_distribution_quantity[value='75']")
    expect(page).to have_selector("input#item_package_size[value='50']")
  end

  scenario "User updates an existing item with empty attributes" do
    item = create(:item)
    visit url_prefix + "/items/#{item.id}/edit"
    fill_in "Name", with: ""
    click_button "Save"

    expect(page.find(".alert")).to have_content "didn't work"
  end

  scenario "User can filter the #index by base item" do
    Item.delete_all
    create(:item, base_item: BaseItem.first)
    create(:item, base_item: BaseItem.last)
    visit url_prefix + "/items"
    select BaseItem.first.name, from: "filters_by_base_item"
    click_button "Filter"
    within "#tbl_items" do
      expect(page).to have_css("tbody tr", count: 1)
    end
  end

  scenario "User can delete an item" do
    item = create(:item, organization: @user.organization)
    visit url_prefix + "/items"
    expect do
      within "tr[data-item-id='#{item.id}']" do
        click_on "Delete", match: :first
      end
    end.to change { Item.count }.by(-1)
  end

  scenario "A user can 'delete' an item that has history, but it only soft-deletes it" do
    item = create(:item, name: "DELETEME", organization: @user.organization)
    create(:donation, :with_items, item: item)
    visit url_prefix + "/items"
    expect(page).to have_content("DELETEME")
    expect do
      within "tr[data-item-id='#{item.id}']" do
        click_on "Delete", match: :first
      end
    end.not_to change { Item.count }
    item.reload
    expect(item).not_to be_active
    visit url_prefix + "/items"
    expect(page).not_to have_content("DELETEME")
  end

  describe "Item Table Tabs >" do
    let(:item_pullups) { create(:item, name: "the most wonderful magical pullups that truly potty train", category: "Magic Toddlers") }
    let(:item_tampons) { create(:item, name: "blackbeard's rugged tampons", category: "Menstrual Products") }
    let(:storage_name) { "the poop catcher warehouse" }
    let(:storage) { create(:storage_location, :with_items, item: item_pullups, item_quantity: num_pullups_in_donation, name: storage_name) }
    let!(:aux_storage) { create(:storage_location, :with_items, item: item_pullups, item_quantity: num_pullups_second_donation, name: "a secret secondary location") }
    let(:num_pullups_in_donation) { 666 }
    let(:num_pullups_second_donation) { 1 }
    let(:num_tampons_in_donation) { 42 }
    let(:num_tampons_second_donation) { 17 }
    let!(:donation_tampons) { create(:donation, :with_items, storage_location: storage, item_quantity: num_tampons_in_donation, item: item_tampons) }
    let!(:donation_aux_tampons) { create(:donation, :with_items, storage_location: aux_storage, item_quantity: num_tampons_second_donation, item: item_tampons) }
    before do
      visit url_prefix + "/items"
    end
    # Consolidated these into one to reduce the setup/teardown
    scenario "Displays items in separate tabs", js: true do
      tab_items_only_text = page.find("table#tbl_items", visible: true).text
      expect(tab_items_only_text).not_to have_content "Quantity"
      expect(tab_items_only_text).to have_content item_pullups.name
      expect(tab_items_only_text).to have_content item_tampons.name

      click_link "Items and Quantity" # href="#sectionB"
      tab_items_and_quantity_text = page.find("table#tbl_items_quantity", visible: true).text
      expect(tab_items_and_quantity_text).to have_content "Quantity"
      expect(tab_items_and_quantity_text).not_to have_content storage_name
      expect(tab_items_and_quantity_text).to have_content num_pullups_in_donation
      expect(tab_items_and_quantity_text).to have_content num_pullups_second_donation
      expect(tab_items_and_quantity_text).to have_content num_tampons_in_donation
      expect(tab_items_and_quantity_text).to have_content num_tampons_second_donation
      expect(tab_items_and_quantity_text).to have_content item_pullups.name
      expect(tab_items_and_quantity_text).to have_content item_tampons.name

      click_link "Items, Quantity, and Location" # href="#sectionC"
      tab_items_quantity_location_text = page.find("table#tbl_items_location", visible: true).text
      expect(tab_items_quantity_location_text).to have_content "Quantity"
      expect(tab_items_quantity_location_text).to have_content storage_name
      expect(tab_items_quantity_location_text).to have_content num_pullups_in_donation
      expect(tab_items_quantity_location_text).to have_content num_pullups_second_donation
      expect(tab_items_quantity_location_text).to have_content num_pullups_in_donation + num_pullups_second_donation
      expect(tab_items_quantity_location_text).to have_content num_tampons_in_donation
      expect(tab_items_quantity_location_text).to have_content num_tampons_second_donation
      expect(tab_items_quantity_location_text).to have_content num_tampons_in_donation + num_tampons_second_donation
      expect(tab_items_quantity_location_text).to have_content item_pullups.name
      expect(tab_items_quantity_location_text).to have_content item_tampons.name
    end
  end
end
