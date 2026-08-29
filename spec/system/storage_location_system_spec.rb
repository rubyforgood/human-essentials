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

      expect(page.find("[data-flash]")).to have_content "added"
    end

    it "User creates a new storage location with the same name" do
      visit subject
      storage_location1 = create(:storage_location, name: "non-Unique Name")

      fill_in "Name", with: storage_location1.name
      fill_in "Address", with: storage_location1.address
      click_on "Save"

      expect(page).to have_content "Name has already been taken"
    end

    it "User creates a new storage location with the same name with different casing" do
      visit subject
      storage_location1 = create(:storage_location, name: "non-Unique Name")

      fill_in "Name", with: storage_location1.name.upcase
      fill_in "Address", with: storage_location1.address
      click_on "Save"

      expect(page).to have_content "Name has already been taken"
    end

    it 'User creates a new storage location with optional fields' do
      visit subject
      storage_location_traits = attributes_for(:storage_location)
      fill_in "Name", with: storage_location_traits[:name]
      fill_in "Address", with: storage_location_traits[:address]
      fill_in "Square footage", with: storage_location_traits[:square_footage]
      select StorageLocation::WAREHOUSE_TYPES.sample, from: 'Warehouse type'
      click_on "Save"

      expect(page.find("[data-flash]")).to have_content "added"
    end

    it "User creates a new storage location with empty attributes" do
      visit subject
      click_on "Save"

      expect(page).to have_css("[data-error-summary]", text: /prevented this from being saved/)
    end
  end

  context "when editing an existing storage location" do
    subject { edit_storage_location_path(storage_location.id) }

    it "User updates an existing storage location" do
      visit subject
      fill_in "Address", with: storage_location.name + " new"
      fill_in "Square footage", with: 50
      select (StorageLocation::WAREHOUSE_TYPES - [storage_location.warehouse_type]).sample, from: 'Warehouse type'

      click_on "Save"

      expect(page.find("[data-flash]")).to have_content "updated"
    end

    it "User updates an existing storage location with empty name" do
      visit subject
      fill_in "Name", with: ""
      click_on "Save"

      expect(page).to have_css("[data-error-summary]", text: /prevented this from being saved/)
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

      # The View button is gone: the location's name in the first cell already links to it, and
      # design.md keeps a visible View only where the row does not link to its own record.
      click_on location1.name

      click_on "Coming in"

      within "#panel-in" do
        expect(page).to have_content("Needle")
        expect(page).to have_content(100)
      end

      within("[role=tablist]") { click_on "Inventory" }

      within "#panel-inventory" do
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

      open_filters
      select item.name, from: "filters[containing]"
      wait_for_filters

      expect(page).to have_css("table tr", count: 3)
      expect(page).to have_xpath("//table/tbody/tr/td", text: location1.name)
      expect(page).not_to have_xpath("//table/tbody/tr/td", text: location2.name)
      expect(page).not_to have_xpath("//table/tbody/tr/td", text: location3.name)

      open_filters
      check "include_inactive_storage_locations"
      wait_for_filters

      expect(page).to have_css("table tr", count: 4)
      expect(page).to have_xpath("//table/tbody/tr/td", text: location3.name)
    end

    it "Allows user to filter discarded storage locations" do
      location1 = create(:storage_location, name: "Bar")
      location2 = create(:storage_location, discarded_at: rand(2.years).seconds.ago)
      visit subject

      expect(page).to have_xpath("//table/tbody/tr/td", text: location1.name)
      expect(page).not_to have_xpath("//table/tbody/tr/td", text: location2.name)

      open_filters
      check "include_inactive_storage_locations"
      wait_for_filters

      expect(page).to have_xpath("//table/tbody/tr/td", text: location1.name)
      expect(page).to have_xpath("//table/tbody/tr/td", text: location2.name)
    end

    it "Stops a user from deactivating storage locations with inventory" do
      location1 = create(:storage_location, :with_items)
      visit subject

      # The action is in the row's overflow menu now, still a real disabled <button> so the
      # state reaches assistive tech, with the reason as sr-only text.
      menu = open_row_menu(row: location1.name)
      expect(menu).to have_button("Deactivate", disabled: true)
      # Visible help text now, not sr-only -- and its own sentence, because it is no longer read
      # after the label by a screen reader.
      expect(menu).to have_text("This location still holds inventory")
    end

    it "Allows user to deactivate and reactivate storage locations" do
      location1 = create(:storage_location)
      visit subject

      expect(accept_confirm { click_row_action "Deactivate", row: location1.name }).to include "Are you sure you want to deactivate #{location1.name}"
      expect(page.find("[data-flash]")).to have_content "Storage Location deactivated successfully"

      open_filters
      check "include_inactive_storage_locations"
      wait_for_filters

      expect(accept_confirm { click_row_action "Reactivate", row: location1.name }).to include "Are you sure you want to reactivate #{location1.name}"

      # Wait for the reactivation itself before looking at the message. Filtering leaves the
      # previous flash in place -- it describes something that did happen -- so a bare check for
      # "a flash" is satisfied by the old one and races the navigation instead of waiting for it.
      # Reactivate disappearing is the outcome; the Deactivate that replaces it is disabled
      # whenever the location holds inventory, so its presence is not a signal.
      expect(page).to have_no_button("Reactivate")

      # Asserted against the page rather than a node found first: reactivating replaces the flash
      # frame, so a node captured beforehand is the previous message and never changes.
      expect(page).to have_css("[data-flash]", text: "Storage Location reactivated successfully")
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

      open_filters
      expect(page.all('select[name="filters[containing]"] option').map(&:text).compact_blank).to eq(expected_order)
      expect(page.all('select[name="filters[containing]"] option').map(&:text).compact_blank).not_to eq(expected_order.reverse)
    end
  end

  context "when viewing an existing storage location" do
    let(:item) { create(:item, name: "AAA Diapers") }
    let!(:storage_location) { create(:storage_location, :with_items, item: item, name: "here") }
    let!(:adjustment) { create(:adjustment, :with_items, storage_location: storage_location) }
    subject { storage_location_path(storage_location.id) }

    it "Items in (adjustments)" do
      visit subject
      click_on "Coming in"

      expect(page.find("#panel-in", visible: true)).to have_content "100"
    end

    it "Items out (distributions)" do
      create(:distribution, :with_items, storage_location: storage_location)
      visit subject
      click_on "Going out"

      expect(page.find("#panel-out", visible: true)).to have_content "100"
    end

    describe "the inventory date filter" do
      it "reports itself as a chip and clears from one" do
        visit subject

        open_filters
        fill_in "Show inventory at date", with: "2024-01-15"
        wait_for_filters

        expect(page).to have_content("Show inventory at date:")
        expect(page).to have_link("Clear all")

        click_on "Clear all"
        wait_for_filters

        expect(page).not_to have_content("Show inventory at date:")
        # The caption is the table's accessible name and `.data-table caption` hides it visually,
        # so it is matched with visible: :all rather than as page text.
        expect(page).to have_css("#panel-inventory caption",
          text: "Items currently at #{storage_location.name}", visible: :all)
      end

      # It applies into a frame rather than reloading, and the difference is load-bearing: a
      # reload re-renders the tab strip with the first tab selected, so before the frame this
      # only worked because Inventory happens to be the first of the three.
      it "leaves the tab strip alone" do
        visit subject

        open_filters
        fill_in "Show inventory at date", with: "2024-01-15"
        wait_for_filters

        expect(page).to have_css("#tab-inventory[aria-selected='true']")
        expect(page.find("#panel-inventory", visible: true)).to be_present
      end
    end
  end
end
