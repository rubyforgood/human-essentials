RSpec.describe "Storage Locations", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before do
    sign_in(user)
  end
  let(:storage_location) { create(:storage_location) }

  context "when creating a new storage location" do
    subject { new_storage_location_path }

    it "User creates a new storage location" do
      visit subject
      storage_location_traits = attributes_for(:storage_location)
      fill_in "Name", with: storage_location_traits[:name]
      fill_in "Address", with: storage_location_traits[:address]
      click_on "Save"

      expect(page.find(".alert")).to have_content "added"
    end

    it 'User creates a new storage location with optional fields' do
      visit subject
      storage_location_traits = attributes_for(:storage_location)
      fill_in "Name", with: storage_location_traits[:name]
      fill_in "Address", with: storage_location_traits[:address]
      fill_in "Square Footage", with: storage_location_traits[:square_footage]
      select StorageLocation::WAREHOUSE_TYPES.sample, from: 'Warehouse Type'
      click_on "Save"

      expect(page.find(".alert")).to have_content "added"
    end

    it "User creates a new storage location with empty attributes" do
      visit subject
      click_on "Save"

      expect(page.find(".alert")).to have_content "didn't work"
    end
  end

  context "when editing an existing storage location" do
    subject { edit_storage_location_path(storage_location.id) }

    it "User updates an existing storage location" do
      visit subject
      fill_in "Address", with: storage_location.name + " new"
      fill_in "Square Footage", with: storage_location.square_footage + 50
      select (StorageLocation::WAREHOUSE_TYPES - [storage_location.warehouse_type]).sample, from: 'Warehouse Type'

      click_on "Save"

      expect(page.find(".alert")).to have_content "updated"
    end

    it "User updates an existing storage location with empty name" do
      visit subject
      fill_in "Name", with: ""
      click_on "Save"

      expect(page.find(".alert")).to have_content "didn't work"
    end
  end

  context "when viewing the index" do
    subject { storage_locations_path }

    # BUG#1008
    it "shows totals that are the sum totals of all inputs" do
      item = create(:item, name: "Needle")
      location1 = create(:storage_location, name: "Foo")
      create(:donation, :with_items, item: item, item_quantity: 51, storage_location: location1)
      create(:purchase, :with_items, item: item, item_quantity: 49, storage_location: location1)

      visit subject

      click_on "View", match: :first

      find("#custom-tabs-inventory-in-tab").click

      within "#custom-tabs-inventory-in" do
        expect(page).to have_content("Needle")
        expect(page).to have_content(100)
      end

      find("#custom-tabs-inventory-tab").click

      within "#custom-tabs-inventory" do
        expect(page).to have_content("Needle")
        expect(page).to have_content(100)
      end
    end

    it "User can filter the #index by those that contain certain items" do
      item = create(:item, name: Faker::Lorem.unique.word)
      create(:item, name: Faker::Lorem.unique.word)
      location1 = create(:storage_location, :with_items, item: item, item_quantity: 10, name: "Foo")
      location2 = create(:storage_location, name: "Bar")
      location3 = create(:storage_location, :with_items, item: item, item_quantity: 10, name: "Baz", discarded_at: rand(2.years).seconds.ago)
      visit subject

      select item.name, from: "filters[containing]"
      click_button "Filter"

      expect(page).to have_css("table tr", count: 2)
      expect(page).to have_xpath("//table/tbody/tr/td", text: location1.name)
      expect(page).not_to have_xpath("//table/tbody/tr/td", text: location2.name)
      expect(page).not_to have_xpath("//table/tbody/tr/td", text: location3.name)

      check "include_inactive_storage_locations"
      click_button "Filter"

      expect(page).to have_css("table tr", count: 3)
      expect(page).to have_xpath("//table/tbody/tr/td", text: location3.name)
    end

    it "Allows user to filter discarded storage locations" do
      location1 = create(:storage_location, name: "Bar")
      location2 = create(:storage_location, discarded_at: rand(2.years).seconds.ago)
      visit subject

      expect(page).to have_xpath("//table/tbody/tr/td", text: location1.name)
      expect(page).not_to have_xpath("//table/tbody/tr/td", text: location2.name)

      check "include_inactive_storage_locations"
      click_button "Filter"

      expect(page).to have_xpath("//table/tbody/tr/td", text: location1.name)
      expect(page).to have_xpath("//table/tbody/tr/td", text: location2.name)
    end

    it "Stops a user from deactivating storage locations with inventory" do
      location1 = create(:storage_location, :with_items)
      visit subject

      expect(accept_confirm { click_on "Deactivate", match: :first }).to include "Are you sure you want to deactivate #{location1.name}"
      expect(page.find(".alert")).to have_content "Cannot deactivate storage location containing inventory items with non-zero quantities"
    end

    it "Allows user to deactivate and reactivate storage locations" do
      location1 = create(:storage_location)
      visit subject

      expect(accept_confirm { click_on "Deactivate", match: :first }).to include "Are you sure you want to deactivate #{location1.name}"
      expect(page.find(".alert")).to have_content "Storage Location deactivated successfully"

      check "include_inactive_storage_locations"
      click_button "Filter"

      expect(accept_confirm { click_on "Reactivate", match: :first }).to include "Are you sure you want to reactivate #{location1.name}"
      expect(page.find(".alert")).to have_content "Storage Location reactivated successfully"
    end

    it "Filter list presented to user is in alphabetical order by item name" do
      item1 = create(:item, name: "AAA Diapers")
      item2 = create(:item, name: "ABC Diapers")
      item3 = create(:item, name: "Wonder Diapers")
      expected_order = [item1.name, item2.name, item3.name]
      create(:storage_location, :with_items, item: item2, item_quantity: 10, name: "Foo")
      create(:storage_location, :with_items, item: item1, item_quantity: 10, name: "Bar")
      create(:storage_location, :with_items, item: item3, item_quantity: 10, name: "Baz")
      visit subject

      expect(page.all('select[name="filters[containing]"] option').map(&:text).select(&:present?)).to eq(expected_order)
      expect(page.all('select[name="filters[containing]"] option').map(&:text).select(&:present?)).not_to eq(expected_order.reverse)
    end
  end

  context "when viewing an existing storage location" do
    let(:item) { create(:item, name: "AAA Diapers") }
    let!(:storage_location) { create(:storage_location, :with_items, item: item, name: "here") }
    let!(:adjustment) { create(:adjustment, :with_items, storage_location: storage_location) }
    subject { storage_location_path(storage_location.id) }

    it "Items in (adjustments)" do
      visit subject
      find("#custom-tabs-inventory-in-tab").click

      expect(page.find("#custom-tabs-inventory-in", visible: true)).to have_content "100"
    end

    it "Items out (distributions)" do
      create(:distribution, :with_items, storage_location: storage_location)
      visit subject
      find("#custom-tabs-inventory-out-tab").click

      expect(page.find("#custom-tabs-inventory-out", visible: true)).to have_content "100"
    end
  end
end
