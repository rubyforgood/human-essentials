RSpec.describe "Donations", type: :system, js: true do
  before do
    sign_in @user
    @url_prefix = "/#{@organization.short_name}"
  end

  context "When visiting the index page" do
    before(:each) do
      create(:donation)
      create(:donation)
      visit @url_prefix + "/donations"
    end

    it "Allows User to click to the new donation form" do
      find(".fa-plus").click

      expect(current_path).to eq(new_donation_path(@organization))
      expect(page).to have_content "Start a new donation"
    end

    it "Displays Total quantity on the index page" do
      expect(page.find(:css, "table.table-hover", visible: true)).to have_content("20")
    end
  end

  context "When filtering on the index page" do
    let!(:item) { create(:item) }
    it "Filters by the source" do
      create(:donation)
      create(:donation_site_donation)
      visit @url_prefix + "/donations"
      expect(page).to have_css("table tbody tr", count: 3)
      select Donation::SOURCES[:misc], from: "filters_by_source"
      click_button "Filter"
      expect(page).to have_css("table tbody tr", count: 2)
    end
    it "Filters by diaper drive" do
      a = create(:diaper_drive_participant, business_name: "A")
      b = create(:diaper_drive_participant, business_name: "B")
      create(:diaper_drive_donation, diaper_drive_participant: a)
      create(:diaper_drive_donation, diaper_drive_participant: b)
      visit @url_prefix + "/donations"
      expect(page).to have_css("table tbody tr", count: 3)
      select a.business_name, from: "filters_by_diaper_drive_participant"
      click_button "Filter"
      expect(page).to have_css("table tbody tr", count: 2)
    end
    it "Filters by manufacturer" do
      a = create(:manufacturer, name: "A")
      b = create(:manufacturer, name: "B")
      create(:manufacturer_donation, manufacturer: a)
      create(:manufacturer_donation, manufacturer: b)
      visit @url_prefix + "/donations"
      expect(page).to have_css("table tbody tr", count: 3)
      select a.name, from: "filters_from_manufacturer"
      click_button "Filter"
      expect(page).to have_css("table tbody tr", count: 2)
    end
    it "Filters by donation site" do
      location1 = create(:donation_site, name: "location 1")
      location2 = create(:donation_site, name: "location 2")
      create(:donation, donation_site: location1)
      create(:donation, donation_site: location2)
      visit @url_prefix + "/donations"
      select location1.name, from: "filters_from_donation_site"
      click_button "Filter"
      expect(page).to have_css("table tbody tr", count: 2)
    end
    it "Filters by storage location" do
      storage1 = create(:storage_location, name: "storage1")
      storage2 = create(:storage_location, name: "storage2")
      create(:donation, storage_location: storage1)
      create(:donation, storage_location: storage2)
      visit @url_prefix + "/donations"
      expect(page).to have_css("table tbody tr", count: 3)
      select storage1.name, from: "filters_at_storage_location"
      click_button "Filter"
      expect(page).to have_css("table tbody tr", count: 2)
    end
    it "Filters by date" do
      storage = create(:storage_location, name: "storage")
      create(:donation, storage_location: storage, issued_at: Date.new(2018, 3, 1))
      create(:donation, storage_location: storage, issued_at: Date.new(2018, 3, 1))
      create(:donation, storage_location: storage, issued_at: Date.new(2018, 2, 1))
      visit @url_prefix + "/donations"
      select "March", from: "date_filters_issued_at_2i"
      select "2018", from: "date_filters_issued_at_1i"
      click_button "Filter"
      expect(page).to have_css("table tbody tr", count: 3)
      select "February", from: "date_filters_issued_at_2i"
      click_button "Filter"
      expect(page).to have_css("table tbody tr", count: 2)
    end
    it "Filters by multiple attributes" do
      storage1 = create(:storage_location, name: "storage1")
      storage2 = create(:storage_location, name: "storage2")
      create(:donation, storage_location: storage1)
      create(:donation, storage_location: storage2)
      create(:donation_site_donation, storage_location: storage1)
      visit @url_prefix + "/donations"
      expect(page).to have_css("table tbody tr", count: 4)
      select Donation::SOURCES[:misc], from: "filters_by_source"
      click_button "Filter"
      expect(page).to have_css("table tbody tr", count: 3)
      select storage1.name, from: "filters_at_storage_location"
      click_button "Filter"
      expect(page).to have_css("table tbody tr", count: 2)
    end
  end

  context "When creating a new donation" do
    before(:each) do
      create(:item, organization: @organization)
      create(:storage_location, organization: @organization)
      create(:donation_site, organization: @organization)
      create(:diaper_drive_participant, organization: @organization)
      create(:manufacturer, organization: @organization)
      @organization.reload
    end

    context "Via manual entry" do
      before(:each) do
        visit @url_prefix + "/donations/new"
      end

      it "Allows donations to be created IN THE PAST" do
        select Donation::SOURCES[:misc], from: "donation_source"
        select StorageLocation.first.name, from: "donation_storage_location_id"
        select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
        fill_in "donation_line_items_attributes_0_quantity", with: "5"
        fill_in "donation_issued_at", with: "01/01/2001"

        expect do
          click_button "Save"
        end.to change { Donation.count }.by(1)

        expect(Donation.last.issued_at).to eq("01/01/2001")
      end

      it "Accepts and combines multiple line items for the same item type" do
        select Donation::SOURCES[:misc], from: "donation_source"
        select StorageLocation.first.name, from: "donation_storage_location_id"
        select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
        fill_in "donation_line_items_attributes_0_quantity", with: "5"
        page.find(:css, "#__add_line_item").click
        select_id = page.find(:xpath, '//*[@id="donation_line_items"]/div[2]/select')[:id]
        select Item.alphabetized.first.name, from: select_id
        text_id = page.find(:xpath, '//*[@id="donation_line_items"]/div[2]/input[2]')[:id]
        fill_in text_id, with: "10"

        expect do
          click_button "Save"
        end.to change { Donation.count }.by(1)

        expect(Donation.last.line_items.first.quantity).to eq(15)
      end

      it "Allows User to create a donation for a Diaper Drive source" do
        select Donation::SOURCES[:diaper_drive], from: "donation_source"
        expect(page).to have_xpath("//select[@id='donation_diaper_drive_participant_id']")
        expect(page).not_to have_xpath("//select[@id='donation_donation_site_id']")
        expect(page).not_to have_xpath("//select[@id='donation_manufacturer_id']")
        select DiaperDriveParticipant.first.business_name, from: "donation_diaper_drive_participant_id"
        select StorageLocation.first.name, from: "donation_storage_location_id"
        select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
        fill_in "donation_line_items_attributes_0_quantity", with: "5"

        expect do
          click_button "Save"
        end.to change { Donation.count }.by(1)
      end

      it "Allows User to create a Diaper Drive from donation" do
        select Donation::SOURCES[:diaper_drive], from: "donation_source"
        select "---Create new diaper drive---", from: "donation_diaper_drive_participant_id"
        expect(page).to have_content("New Diaper Drive Participant")
        fill_in "diaper_drive_participant_business_name", with: "businesstest"
        fill_in "diaper_drive_participant_contact_name", with: "test"
        fill_in "diaper_drive_participant_email", with: "123@mail.ru"
        click_on "diaper-drive-participant-submit"
        select "businesstest", from: "donation_diaper_drive_participant_id"
      end

      it "Allows User to create a donation for a Manufacturer source" do
        select Donation::SOURCES[:manufacturer], from: "donation_source"
        expect(page).to have_xpath("//select[@id='donation_manufacturer_id']")
        expect(page).not_to have_xpath("//select[@id='donation_diaper_drive_participant_id']")
        expect(page).not_to have_xpath("//select[@id='donation_donation_site_id']")
        select Manufacturer.first.name, from: "donation_manufacturer_id"
        select StorageLocation.first.name, from: "donation_storage_location_id"
        select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
        fill_in "donation_line_items_attributes_0_quantity", with: "5"

        expect do
          click_button "Save"
        end.to change { Donation.count }.by(1)
      end

      it "Allows User to create a Manufacturer from donation" do
        select Donation::SOURCES[:manufacturer], from: "donation_source"
        select "---Create new Manufacturer---", from: "donation_manufacturer_id"
        expect(page).to have_content("New Manufacturer")
        fill_in "manufacturer_name", with: "nametest"
        click_on "manufacturer-submit"
        select "nametest", from: "donation_manufacturer_id"
      end

      it "Allows User to create a donation for a Donation Site source" do
        select Donation::SOURCES[:donation_site], from: "donation_source"
        expect(page).to have_xpath("//select[@id='donation_donation_site_id']")
        expect(page).not_to have_xpath("//select[@id='donation_diaper_drive_participant_id']")
        expect(page).not_to have_xpath("//select[@id='donation_manufacturer_id']")
        select DonationSite.first.name, from: "donation_donation_site_id"
        select StorageLocation.first.name, from: "donation_storage_location_id"
        select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
        fill_in "donation_line_items_attributes_0_quantity", with: "5"

        expect do
          click_button "Save"
        end.to change { Donation.count }.by(1)
      end

      it "Allows User to create a donation for Purchased Supplies" do
        select Donation::SOURCES[:misc], from: "donation_source"
        expect(page).not_to have_xpath("//select[@id='donation_donation_site_id']")
        expect(page).not_to have_xpath("//select[@id='donation_diaper_drive_participant_id']")
        expect(page).not_to have_xpath("//select[@id='donation_manufacturer_id']")
        select StorageLocation.first.name, from: "donation_storage_location_id"
        select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
        fill_in "donation_line_items_attributes_0_quantity", with: "5"

        expect do
          click_button "Save"
        end.to change { Donation.count }.by(1)
      end

      it "Allows User to create a donation with a Miscellaneous source" do
        select Donation::SOURCES[:misc], from: "donation_source"
        expect(page).not_to have_xpath("//select[@id='donation_donation_site_id']")
        expect(page).not_to have_xpath("//select[@id='donation_diaper_drive_participant_id']")
        expect(page).not_to have_xpath("//select[@id='donation_manufacturer_id']")
        select StorageLocation.first.name, from: "donation_storage_location_id"
        select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
        fill_in "donation_line_items_attributes_0_quantity", with: "5"

        expect do
          click_button "Save"
        end.to change { Donation.count }.by(1)
      end

      # Since the form only shows/hides the irrelevant field, if the user already selected something it would still
      # submit. The app should sanitize this so we aren't saving extraneous data
      it "Strips extraneous data if the user adds both Donation Site and Diaper Drive Participant" do
        select Donation::SOURCES[:donation_site], from: "donation_source"
        select DonationSite.first.name, from: "donation_donation_site_id"
        select Donation::SOURCES[:manufacturer], from: "donation_source"
        select Manufacturer.first.name, from: "donation_manufacturer_id"
        select Donation::SOURCES[:diaper_drive], from: "donation_source"
        select DiaperDriveParticipant.first.business_name, from: "donation_diaper_drive_participant_id"
        select StorageLocation.first.name, from: "donation_storage_location_id"
        select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
        fill_in "donation_line_items_attributes_0_quantity", with: "5"
        click_button "Save"
        donation = Donation.last
        expect(donation.diaper_drive_participant_id).to be_present
        expect(donation.manufacturer_id).to be_nil
        expect(donation.donation_site_id).to be_nil
      end

      # Bug fix -- Issue #71
      # When a user creates a donation without it passing validation, the items
      # dropdown is not populated on the return trip.
      it "Repopulates items dropdown even if initial submission doesn't validate" do
        item_count = @organization.items.count + 1 # Adds 1 for the "choose an item" option
        expect(page).to have_xpath("//select[@id='donation_line_items_attributes_0_item_id']/option", count: item_count)
        click_button "Save"

        expect(page).to have_content("error")
        expect(page).to have_xpath("//select[@id='donation_line_items_attributes_0_item_id']/option", count: item_count)
      end

      # Bug fix -- Issue #526
      it "Ensures Barcode Entry fields have unique ids" do
        page.find(:css, "#__add_line_item").click
        page.find(:css, "#__add_line_item").click
        expect(page).to have_xpath("//input[@id='_barcode-lookup-1']")
        expect(page).to have_xpath("//input[@id='_barcode-lookup-2']")
      end
    end

    context "Via barcode entry" do
      before(:each) do
        initialize_barcodes
        visit @url_prefix + "/donations/new"
      end

      it "Allows User to add items by barcode", :js do
        # enter the barcode into the barcode field

        within "#donation_line_items" do
          expect(page).to have_xpath("//input[@id='_barcode-lookup-0']")
          Barcode.boop(@existing_barcode.value)
        end
        # the form should update
        expect(page).to have_xpath('//input[@id="donation_line_items_attributes_0_quantity"]')
        expect(page.has_select?("donation_line_items_attributes_0_item_id", selected: @existing_barcode.item.name)).to eq(true)
        qty = page.find(:xpath, '//input[@id="donation_line_items_attributes_0_quantity"]').value

        expect(qty).to eq(@existing_barcode.quantity.to_s)
      end

      it "Updates the line item when the same barcode is scanned twice", :js do
        within "#donation_line_items" do
          expect(page).to have_xpath("//input[@id='_barcode-lookup-0']")
          Barcode.boop(@existing_barcode.value)
        end

        expect(page).to have_field "donation_line_items_attributes_0_quantity", with: @existing_barcode.quantity.to_s

        within "#donation_line_items" do
          expect(page).to have_xpath("//input[@id='_barcode-lookup-1']")
          Barcode.boop(@existing_barcode.value)
        end

        expect(page).to have_field "donation_line_items_attributes_0_quantity", with: (@existing_barcode.quantity * 2).to_s
      end

      it "Allows User to add items that do not yet have a barcode", :js do
        new_barcode = @existing_barcode.value + "000"
        # enter a new barcode
        within "#donation_line_items" do
          expect(page).to have_xpath("//input[@id='_barcode-lookup-0']")
          Barcode.boop(new_barcode)
        end

        # form finds no barcode and responds by prompting user to choose an item and quantity
        within "#newBarcode" do
          # fill that in
          fill_in "Quantity", with: 10
          # saves new barcode
          select Item.first.name, from: "Item"
          expect(page).to have_field("barcode_item_quantity", with: '10')
          expect(page).to have_field("barcode_item_value", with: new_barcode)
          click_on "Save"
        end

        within "#donation_line_items" do
          barcode_field = page.find(:xpath, "//input[@id='_barcode-lookup-0']").value
          expect(barcode_field).to eq(new_barcode)
          qty_field = page.find(:xpath, "//input[@id='donation_line_items_attributes_0_quantity']").value
          expect(qty_field).to eq("10")
          item_field = page.find(:xpath, "//select[@id='donation_line_items_attributes_0_item_id']").value
          expect(item_field).to eq(Item.first.id.to_s)
        end
        # form updates
      end

      context "When the barcode is a global barcode" do
        before do
          base_item = BaseItem.first
          # Create a global barcode item first
          @global_barcode = create(:global_barcode_item, barcodeable: base_item)
          # make sure there are no other items associated with that base_item in this org
          Item.where(partner_key: base_item.partner_key).delete_all
          # Now create an item that's associated with that base item,
          @item = create(:item, base_item: base_item, organization: @organization, created_at: 1.week.ago)
        end

        it "Adds the oldest item it can find for the global barcode" do
          visit @url_prefix + "/donations/new"
          within "#donation_line_items" do
            expect(page).to have_xpath("//input[@id='_barcode-lookup-0']")
            Barcode.boop(@global_barcode.value)
          end
          expect(page).to have_xpath('//input[@id="donation_line_items_attributes_0_quantity"]')
          expect(page.has_select?("donation_line_items_attributes_0_item_id", selected: @item.name)).to eq(true)
          qty = page.find(:xpath, '//input[@id="donation_line_items_attributes_0_quantity"]').value

          expect(qty).to eq(@global_barcode.quantity.to_s)
        end
      end
    end
  end

  context "When donation items have value" do
    before do
      item1 = create(:item, value_in_cents: 125)
      item2 = create(:item)
      item3 = create(:item, value_in_cents: 200)
      @donation1 = create(:donation, :with_items, item: item1)
      create(:donation, :with_items, item: item2)
      create(:donation, :with_items, item: item3)

      visit @url_prefix + "/donations"
    end

    it 'Displays the individual value on the index page' do
      expect(page).to have_content "$125"
    end

    it 'Displays the total value on the index page' do
      expect(page).to have_content "$325"
    end

    it 'Displays the total value on the show page' do
      visit @url_prefix + "/donations/#{@donation1.id}"
      expect(page).to have_content "$125"
    end
  end
end
