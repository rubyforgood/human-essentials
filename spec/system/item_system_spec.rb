RSpec.describe "Item management", type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before do
    sign_in(user)
  end

  it "can create a new item as a user" do
    create(:base_item, name: "BaseItem")
    item_traits = attributes_for(:item)

    visit new_item_path
    fill_in "Name", with: item_traits[:name]
    select "BaseItem", from: "Base Item"
    click_button "Save"

    expect(page.find(".alert")).to have_content "added"
  end

  it "can create a new item with empty attributes as a user" do
    visit new_item_path
    click_button "Save"

    expect(page.find(".alert")).to have_content "Base item must exist and Name can't be blank"
  end

  it "can create a new item with dollars decimal amount for value field" do
    create(:base_item, name: "BaseItem")
    item_traits = attributes_for(:item)

    visit new_item_path

    fill_in "Name", with: item_traits[:name]
    fill_in "item_value_in_dollars", with: '1,234.56'
    select "BaseItem", from: "Base Item"
    click_button "Save"

    expect(page.find(".alert")).to have_content "added"
    expect(Item.last.value_in_dollars).to eq(1234.56)
    expect(Item.last.value_in_cents).to eq(123_456)
  end

  it "can update an existing item as a user" do
    item = create(:item)
    visit edit_item_path(item.id)
    click_button "Save"

    expect(page.find(".alert")).to have_content "updated"
  end

  it "can update an existing item with empty attributes as a user" do
    item = create(:item)
    visit edit_item_path(item.id)
    fill_in "Name", with: ""
    click_button "Save"

    expect(page.find(".alert")).to have_content "didn't work"
  end

  it "can make the item invisible to partners" do
    item = create(:item)
    visit edit_item_path(item.id)
    uncheck "visible_to_partners"
    click_button "Save"
    visit edit_item_path(item.id)

    # rubocop:disable Rails/DynamicFindBy
    expect(find_by_id("visible_to_partners").checked?).to be false
    # rubocop:enable Rails/DynamicFindBy

    expect(item.reload.visible_to_partners).to be false
  end

  it "can filter the #index by base item as a user" do
    Item.delete_all
    base_item1 = create(:base_item, name: "First Base Item")
    base_item2 = create(:base_item)
    create(:item, base_item: base_item1)
    create(:item, base_item: base_item2)

    visit items_path
    select "First Base Item", from: "filters[by_base_item]"
    click_button "Filter"
    within "#items-table" do
      expect(page).to have_css("tbody tr", count: 1)
    end
  end

  describe "restoring items" do
    let!(:item) { create(:item, :inactive, name: "AAA DELETED") }

    it "allows a user to restore the item" do
      expect do
        visit items_path
        check "include_inactive_items"
        click_on "Filter"
        within "#items-table" do
          expect(page).to have_content(item.name)
        end

        within "tr[data-item-id='#{item.id}']" do
          accept_confirm do
            click_on "Restore", match: :first
          end
        end
        page.find(".alert-info")
      end.to change { Item.count }.by(0).and change { Item.active.count }.by(1)
      item.reload
      expect(item).to be_active
    end
  end

  describe "Item Table Tabs >" do
    let(:item_pullups) { create(:item, name: "the most wonderful magical pullups that truly potty train", category: "Magic Toddlers") }
    let(:item_tampons) { create(:item, name: "blackbeard's rugged tampons", category: "Menstrual Products") }
    let(:storage_name) { "the poop catcher warehouse" }
    let(:storage) { create(:storage_location, :with_items, item: item_pullups, item_quantity: num_pullups_in_donation, name: storage_name) }
    let!(:aux_storage) { create(:storage_location, :with_items, item: item_pullups, item_quantity: num_pullups_second_donation, name: "a secret secondary location") }
    let(:num_pullups_in_donation) { 666 }
    let(:num_pullups_second_donation) { 15 }
    let(:num_tampons_in_donation) { 42 }
    let(:num_tampons_second_donation) { 17 }
    let!(:donation_tampons) { create(:donation, :with_items, storage_location: storage, item_quantity: num_tampons_in_donation, item: item_tampons) }
    let!(:donation_aux_tampons) { create(:donation, :with_items, storage_location: aux_storage, item_quantity: num_tampons_second_donation, item: item_tampons) }
    before do
      visit items_path
    end

    # Consolidated these into one to reduce the setup/teardown
    it "should display items in separate tabs", js: true do
      tab_items_only_text = page.find("#items-table", visible: true).text
      expect(tab_items_only_text).to have_content item_pullups.name
      expect(tab_items_only_text).to have_content item_tampons.name

      click_link "Items, Quantity, and Location" # href="#sectionC"
      tab_items_quantity_location_text = page.find(".table-items-location", visible: true).text
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

    it "should display an Item Inventory table", js: true do
      click_link "Item Inventory" # href="#sectionD"
      tab_items_quantity_location_text = page.find(".table-items-location", visible: true).text
      expect(tab_items_quantity_location_text).to have_content "Quantity"
      expect(tab_items_quantity_location_text).to have_content item_pullups.name
      expect(tab_items_quantity_location_text).to have_content item_tampons.name
      expect(tab_items_quantity_location_text).to have_content num_pullups_in_donation + num_pullups_second_donation
      expect(tab_items_quantity_location_text).to have_content num_tampons_in_donation + num_tampons_second_donation
      expect(tab_items_quantity_location_text).not_to have_content storage_name
      expect(tab_items_quantity_location_text).not_to have_content num_pullups_in_donation
      expect(tab_items_quantity_location_text).not_to have_content num_pullups_second_donation
      expect(tab_items_quantity_location_text).not_to have_content num_tampons_in_donation
      expect(tab_items_quantity_location_text).not_to have_content num_tampons_second_donation
      expandable_row = find("td", text: item_tampons.name).find(:xpath, "..")
      expandable_row.click
      expanded_row = find(".expandable-body", visible: true).text
      expect(find(".expandable-body", visible: true)).to have_link storage_name
      expect(expanded_row).to have_content num_tampons_in_donation
      expect(expanded_row).to have_content num_tampons_second_donation
    end
  end

  describe 'Item Category Management' do
    let!(:base_item) { create(:base_item, name: "BaseItem") }
    let!(:item) { create(:item, name: "SomeRandomItem", organization: organization) }

    before do
      visit items_path
    end

    describe 'creating a new item category and associating to a new item' do
      let(:new_item_name) { 'Test Item' }
      let(:new_item_category) { 'Test Category' }

      before do
        click_on 'Item Categories'
        click_on 'New Item Category'
        fill_in 'Category Name *', with: new_item_category
        fill_in 'Category Description', with: 'A test category description'
        click_on 'Save'
      end

      context 'and associating to a existing item' do
        before do
          find("tr[data-item-id=\"#{item.id}\"]").find('a', text: 'Edit').click
          select new_item_category, from: 'Category'
          click_on 'Save'
        end

        it 'should associate the item with the category' do
          item_category = ItemCategory.find_by(name: new_item_category)
          expect(item.reload.item_category).to eq(item_category)
        end
      end

      context 'and associating to a new item' do
        let(:new_item_name) { 'Test Item' }

        before do
          click_on 'New Item'
          select "BaseItem", from: 'Base Item'
          fill_in 'Name *', with: new_item_name
          select new_item_category, from: 'Category'

          click_on 'Save'
          expect(page).to have_content("#{new_item_name} added!")
        end

        it 'should create the new item with the correct category' do
          item_category = ItemCategory.find_by(name: new_item_category)
          expect(Item.find_by(name: new_item_name, item_category_id: item_category.id)).not_to be_nil
        end
      end
    end
  end
end

