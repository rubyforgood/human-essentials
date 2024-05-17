RSpec.describe "Adjustment management", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  let!(:storage_location) { create(:storage_location, :with_items, organization: organization) }
  let(:add_quantity) { 10 }
  let(:sub_quantity) { -10 }

  subject { adjustments_path }

  before do
    sign_in(user)
  end

  context "With a new adjustment" do
    context "with a storage location that is bare", js: true do
      let!(:bare_storage_location) { create(:storage_location, name: "We Got Nothin", organization: organization) }

      before do
        visit subject
        click_on "New Adjustment"
        select bare_storage_location.name, from: "From storage location"
      end

      it "allows you to choose items that do not yet exist" do
        find('select option[data-select2-id="3"]', wait: 10)
        select Item.active.last.name, from: "adjustment_line_items_attributes_0_item_id"
        fill_in "adjustment_line_items_attributes_0_quantity", with: add_quantity.to_s

        expect do
          click_on "Save"
        end.to change { bare_storage_location.size }.by(add_quantity)
        expect(page).to have_content(/Adjustment was successful/i)
      end
    end

    context "with a storage location that has inventory" do
      before do
        visit subject
        click_on "New Adjustment"
        select storage_location.name, from: "From storage location"
        fill_in "Comment", with: "something"
        select Item.last.name, from: "adjustment_line_items_attributes_0_item_id"
      end

      it "can add an inventory adjustment at a storage location", js: true do
        fill_in "adjustment_line_items_attributes_0_quantity", with: add_quantity.to_s

        expect do
          click_on "Save"
        end.to change { storage_location.size }.by(add_quantity)
        expect(page).to have_content(/Adjustment was successful/i)
      end

      it "can subtract an inventory adjustment at a storage location", js: true do
        fill_in "adjustment_line_items_attributes_0_quantity", with: sub_quantity.to_s

        expect do
          click_on "Save"
        end.to change { storage_location.size }.by(sub_quantity)
        expect(page).to have_content(/Adjustment was successful/i)
      end

      it "politely informs the user that they're adjusting way too hard", js: true do
        sub_quantity = -9001
        storage_location = create(:storage_location, :with_items, name: "PICK THIS ONE", item_quantity: 10, organization: organization)
        visit adjustments_path
        click_on "New Adjustment"
        select storage_location.name, from: "From storage location"
        fill_in "Comment", with: "something"
        select Item.last.name, from: "adjustment_line_items_attributes_0_item_id"
        fill_in "adjustment_line_items_attributes_0_quantity", with: sub_quantity.to_s

        expect do
          click_button "Save"
        end.not_to change { storage_location.size }
        expect(page).to have_content("items exceed the available inventory")
      end

      it "politely informs the user if they try to adjust down below zero, even if they use multiple adjustments to do so" do
        sub_quantity = -9

        storage_location = create(:storage_location, :with_items, name: "PICK THIS ONE", item_quantity: 10, organization: organization)
        visit adjustments_path
        click_on "New Adjustment"
        select storage_location.name, from: "From storage location"
        fill_in "Comment", with: "something"
        select Item.last.name, from: "adjustment_line_items_attributes_0_item_id"
        fill_in "adjustment_line_items_attributes_0_quantity", with: sub_quantity.to_s
        click_on "Add Another Item"
        within all(".line_item_section").last do
          element_1 = find(".line_item_name")
          expect(page).to have_select(element_1[:id])
          select Item.last.name, from: element_1[:id]
          element_2 = find(".quantity")
          expect(element_2.value).to eq("")
          element_2.set sub_quantity.to_s
        end

        expect do
          click_button "Save"
        end.not_to change { storage_location.size }
        expect(page).to have_content("items exceed the available inventory")
        expect(page).to have_field("adjustment_line_items_attributes_0_quantity", with: "-18")
      end
    end

    it "should not display inactive storage locations in dropdown" do
      create(:storage_location, name: "Inactive R Us", discarded_at: Time.zone.now)
      visit new_adjustment_path
      expect(page).to have_no_content "Inactive R Us"
    end
  end

  it "can filter the #index by storage location" do
    storage_location2 = create(:storage_location, name: "there", organization: organization)
    create(:adjustment, organization: organization, storage_location: storage_location)
    create(:adjustment, organization: organization, storage_location: storage_location2)

    visit subject
    select storage_location.name, from: "filters[at_location]"
    click_on "Filter"

    expect(page).to have_css("table tr", count: 2)
  end

  it "can filter the #index by user" do
    storage_location2 = create(:storage_location, name: "there", organization: organization)
    create(:adjustment, organization: organization, storage_location: storage_location, user_id: user.id)
    create(:adjustment, organization: organization, storage_location: storage_location2, user_id: organization_admin.id)

    visit subject
    select user.name, from: "filters[by_user]"
    click_on "Filter"

    expect(page).to have_css("table tr", count: 2)
  end

  it "should not display inactive storage locations in dropdown" do
    create(:storage_location, name: "Inactive R Us", discarded_at: Time.zone.now)
    visit subject
    expect(page).to have_no_content "Inactive R Us"
  end

  it_behaves_like "Date Range Picker", Adjustment
end
