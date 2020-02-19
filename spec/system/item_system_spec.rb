RSpec.describe "Item management", type: :system do
  before do
    sign_in(@user)
  end
  let!(:url_prefix) { "/#{@organization.to_param}" }
  it "can create a new item as a user" do
    visit url_prefix + "/items/new"
    item_traits = attributes_for(:item)
    fill_in "Name", with: item_traits[:name]
    select BaseItem.last.name, from: "Base Item"
    click_button "Save"

    expect(page.find(".alert")).to have_content "added"
  end

  it "can create a new item with empty attributes as a user" do
    visit url_prefix + "/items/new"
    click_button "Save"

    expect(page.find(".alert")).to have_content "didn't work"
  end

  it "can create a new item with dollars decimal amount for value field" do
    visit url_prefix + "/items/new"
    item_traits = attributes_for(:item)
    fill_in "Name", with: item_traits[:name]
    fill_in "item_value_in_dollars", with: '1,234.56'
    select BaseItem.last.name, from: "Base Item"
    click_button "Save"

    expect(page.find(".alert")).to have_content "added"
    expect(Item.last.value_in_dollars).to eq(1234.56)
    expect(Item.last.value_in_cents).to eq(123_456)
  end

  it "can update an existing item as a user" do
    item = create(:item)
    visit url_prefix + "/items/#{item.id}/edit"
    click_button "Save"

    expect(page.find(".alert")).to have_content "updated"
  end

  it "can update an existing item with empty attributes as a user" do
    item = create(:item)
    visit url_prefix + "/items/#{item.id}/edit"
    fill_in "Name", with: ""
    click_button "Save"

    expect(page.find(".alert")).to have_content "didn't work"
  end

  it "can filter the #index by base item as a user" do
    Item.delete_all
    create(:item, base_item: BaseItem.first)
    create(:item, base_item: BaseItem.last)
    visit url_prefix + "/items"
    select BaseItem.first.name, from: "filters_by_base_item"
    click_button "Filter"
    within ".table" do
      expect(page).to have_css("tbody tr", count: 1)
    end
  end

  it "can include inactive items in the results" do
    Item.delete_all
    create(:item, :inactive, name: "Inactive Item")
    create(:item, :active, name: "Active Item")
    visit url_prefix + "/items"
    expect(page).to have_text("Active Item")
    expect(page).to have_no_text("Inactive Item")
    page.check('include_inactive_items')
    click_button "Filter"
    expect(page).to have_text("Inactive Item")
    expect(page).to have_text("Active Item")
  end

  describe "destroying items" do
    subject { create(:item, name: "DELETEME", organization: @user.organization) }
    context "when an item has history" do
      before do
        create(:donation, :with_items, item: subject)
      end
      it "can be soft-deleted (deactivated) by the user" do
        expect do
          visit url_prefix + "/items"
          expect(page).to have_content(subject.name)
          within "tr[data-item-id='#{subject.id}']" do
            accept_confirm do
              click_on "Delete", match: :first
            end
          end
          page.find(".alert-info")
        end.to change { Item.count }.by(0).and change { Item.active.count }.by(-1)
        subject.reload
        expect(subject).not_to be_active
      end
    end

    context "when an item does not have history" do
      it "can be fully deleted by the user" do
        subject
        expect do
          visit url_prefix + "/items"
          expect(page).to have_content(subject.name)
          within "tr[data-item-id='#{subject.id}']" do
            accept_confirm do
              click_on "Delete", match: :first
            end
          end
          page.find(".alert-info")
        end.to change { Item.count }.by(-1).and change { Item.active.count }.by(-1)
        expect { subject.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "restoring items" do
    let!(:item) { create(:item, :inactive, name: "DELETED") }

    it "allows a user to restore the item" do
      expect do
        visit url_prefix + "/items"
        check "include_inactive_items"
        click_on "Filter"
        within ".table" do
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
    let(:num_pullups_second_donation) { 1 }
    let(:num_tampons_in_donation) { 42 }
    let(:num_tampons_second_donation) { 17 }
    let!(:donation_tampons) { create(:donation, :with_items, storage_location: storage, item_quantity: num_tampons_in_donation, item: item_tampons) }
    let!(:donation_aux_tampons) { create(:donation, :with_items, storage_location: aux_storage, item_quantity: num_tampons_second_donation, item: item_tampons) }
    before do
      visit url_prefix + "/items"
    end
    # Consolidated these into one to reduce the setup/teardown
    it "should display items in separate tabs", js: true do
      tab_items_only_text = page.find(".table", visible: true).text
      expect(tab_items_only_text).not_to have_content "Quantity"
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
  end
end
