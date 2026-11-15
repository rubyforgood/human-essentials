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
      fill_in "Square Footage", with: 50
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

      expect(page).to have_css("table tr", count: 3)
      expect(page).to have_xpath("//table/tbody/tr/td", text: location1.name)
      expect(page).not_to have_xpath("//table/tbody/tr/td", text: location2.name)
      expect(page).not_to have_xpath("//table/tbody/tr/td", text: location3.name)

      check "include_inactive_storage_locations"
      click_button "Filter"

      expect(page).to have_css("table tr", count: 4)
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

      within "form[action='/storage_locations/#{location1.id}/deactivate']" do
        expect(page).to have_button('Deactivate', class: "disabled")
      end
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

      expect(page.all('select[name="filters[containing]"] option').map(&:text).compact_blank).to eq(expected_order)
      expect(page.all('select[name="filters[containing]"] option').map(&:text).compact_blank).not_to eq(expected_order.reverse)
    end
  end

  context "when viewing an existing storage location" do
    let(:items) { create_list(:item, 2) }
    let!(:storage_location) { create(:storage_location, name: "here") }
    subject { storage_location_path(storage_location.id) }

    # @return [Array<Array<String>>] the text of each cell in each body row
    def flow_rows
      all("#custom-tabs-inventory-flow tbody tr").map { |tr| tr.all("td").map(&:text) }
    end

    def flow_totals
      all("#custom-tabs-inventory-flow tfoot td").map(&:text)
    end

    context "Inventory Flow Tab" do
      before do
        create(:donation, :with_items, item: items[0], item_quantity: 10, storage_location: storage_location)
        distribution = create(:distribution, :with_items, item: items[0], item_quantity: 5, storage_location: storage_location)
        DistributionEvent.publish(distribution)
        create(:donation, :with_items, item: items[1], item_quantity: 3, storage_location: storage_location)
        adjustment = create(:adjustment, :with_items, item: items[1], item_quantity: 3, storage_location: storage_location)
        AdjustmentEvent.publish(adjustment)
        transfer = create(:transfer, :with_items, item: items[1], item_quantity: 2, from: storage_location, to: create(:storage_location))
        TransferEvent.publish(transfer)
        visit subject
        find("#custom-tabs-inventory-flow-tab").click
      end

      it "shows the inventory flow for the storage location" do
        expect(page).to have_css("#custom-tabs-inventory-flow tbody tr", count: 2)
        # Columns: item, start, in, out, adjustment/audit, change, end.
        # The adjustment (+3) shows in the adjustment column, not as in.
        expect(flow_rows).to contain_exactly(
          [items[0].name, "0", "10", "5", "0", "5", "5"],
          [items[1].name, "0", "3", "2", "3", "4", "4"]
        )
        expect(flow_totals).to eq(["Total", "0", "13", "7", "3", "9", "9"])
      end

      it "opens an item's page from its link" do
        within("#custom-tabs-inventory-flow tbody") { click_link items[0].name }

        expect(page).to have_current_path(item_path(items[0]))
        expect(page).to have_content(items[0].name)
      end

      context "date range filter" do
        let!(:start_date) { 2.days.ago }
        let!(:end_date) { 1.day.ago }
        let!(:item) { create(:item, name: "Filtered Item") }

        before do
          create(:donation, :with_items, item: item, item_quantity: 10, storage_location: storage_location)
          Event.last.update(event_time: start_date)
          fill_in "filters[date_range]", with: "#{start_date.strftime("%B %d, %Y")} - #{end_date.strftime("%B %d, %Y")}"
          click_button "Filter"
        end

        it "stays on the Inventory Flow tab and filters the flow by date range" do
          expect(page).to have_css("#custom-tabs-inventory-flow-tab.active")
          expect(page).to have_css("#custom-tabs-inventory-flow tbody tr", count: 1)
          # Everything else was recorded today, after the range.
          expect(flow_rows).to eq([["Filtered Item", "0", "10", "0", "0", "10", "10"]])
          expect(flow_totals).to eq(["Total", "0", "10", "0", "0", "10", "10"])
        end
      end
    end
  end
end
