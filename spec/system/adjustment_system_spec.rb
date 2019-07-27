RSpec.describe "Adjustment management", type: :system, js: true do
  let!(:url_prefix) { "/#{@organization.to_param}" }
  let!(:storage_location) { create(:storage_location, :with_items, organization: @organization) }
  let(:add_quantity) { 10 }
  let(:sub_quantity) { -10 }

  subject { url_prefix + "/adjustments" }

  before do
    sign_in(@user)
  end

  context "With a new adjustment" do
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

    it "Does not include inactive items in the line item fields" do
      visit url_prefix + "/adjustments/new"

      item = Item.alphabetized.first

      select storage_location.name, from: "From storage location"
      expect(page).to have_content(item.name)
      select item.name, from: "adjustment_line_items_attributes_0_item_id"

      item.update(active: false)

      page.refresh
      within "#new_adjustment" do
        select storage_location.name, from: "From storage location"
        expect(page).to have_no_content(item.name)
      end
    end
  end

  it "can filter the #index by storage location" do
    storage_location2 = create(:storage_location, name: "there", organization: @organization)
    create(:adjustment, organization: @organization, storage_location: storage_location)
    create(:adjustment, organization: @organization, storage_location: storage_location2)

    visit subject
    select storage_location.name, from: "filters_at_location"
    click_on "Filter"

    expect(page).to have_css("table tr", count: 2)
  end
end
