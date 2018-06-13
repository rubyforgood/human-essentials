RSpec.feature "Donations", type: :feature, js: true do
  before :each do
    sign_in @user
    @url_prefix = "/#{@organization.short_name}"
  end

  context "When visiting the index page" do
    before(:each) do
      create(:donation, source: Donation::SOURCES[:misc])
      create(:donation, source: Donation::SOURCES[:misc])
      visit @url_prefix + "/donations"
    end

    scenario "User can click to the new donation form" do
      find(".fa-plus").click

      expect(current_path).to eq(new_donation_path(@organization))
      expect(page).to have_content "Start a new donation"
    end

    scenario "Total quantity on the index page" do
      expect(page.find(:css, "table.table-hover", visible: true)).to have_content("20")
    end
  end

  context "When filtering on the index page" do
    let!(:item) { create(:item) }
    scenario "User can filter by the source" do
      create(:donation, source: Donation::SOURCES[:misc])
      create(:donation, source: Donation::SOURCES[:donation_site])
      visit @url_prefix + "/donations"
      expect(page).to have_css("table tbody tr", count: 3)
      select Donation::SOURCES[:misc], from: "filters_by_source"
      click_button "Filter"
      expect(page).to have_css("table tbody tr", count: 2)
    end
    scenario "User can filter by diaper drive" do
      a = create(:diaper_drive_participant, name: "A")
      b = create(:diaper_drive_participant, name: "B")
      create(:donation, source: Donation::SOURCES[:diaper_drive], diaper_drive_participant: a)
      create(:donation, source: Donation::SOURCES[:diaper_drive], diaper_drive_participant: b)
      visit @url_prefix + "/donations"
      expect(page).to have_css("table tbody tr", count: 3)
      select a.name, from: "filters_by_diaper_drive_participant"
      click_button "Filter"
      expect(page).to have_css("table tbody tr", count: 2)
    end
    scenario "User can filter by donation site" do
      location1 = create(:donation_site, name: "location 1")
      location2 = create(:donation_site, name: "location 2")
      create(:donation, donation_site: location1)
      create(:donation, donation_site: location2)
      visit @url_prefix + "/donations"
      select location1.name, from: "filters_from_donation_site"
      click_button "Filter"
      expect(page).to have_css("table tbody tr", count: 2)
    end
    scenario "User can filter the #index by storage location" do
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
    scenario "Filters drill down if you pick from multiples" do
      storage1 = create(:storage_location, name: "storage1")
      storage2 = create(:storage_location, name: "storage2")
      create(:donation, storage_location: storage1, source: Donation::SOURCES[:misc])
      create(:donation, storage_location: storage2, source: Donation::SOURCES[:misc])
      create(:donation, storage_location: storage1, source: Donation::SOURCES[:donation_site])
      visit @url_prefix + "/donations"
      expect(page).to have_css("table tbody tr", count: 4)
      select Donation::SOURCES[:misc], from: "filters_by_source"
      click_button "Filter"
      expect(page).to have_css("table tbody tr", count: 3)
      select storage1.name, from: "filters_at_storage_location"
      click_button "Filter"
      expect(page).to have_css("table tbody tr", count: 2)
    end
    scenario "Filter by issued_at" do
      storage = create(:storage_location, name: "storage")
      create(:donation, storage_location: storage, issued_at: Date.new(2018, 3, 1), source: Donation::SOURCES[:misc])
      create(:donation, storage_location: storage, issued_at: Date.new(2018, 3, 1), source: Donation::SOURCES[:misc])
      create(:donation, storage_location: storage, issued_at: Date.new(2018, 2, 1), source: Donation::SOURCES[:misc])
      visit @url_prefix + "/donations"
      select "March", from: "date_filters_issued_at_2i"
      select "2018", from: "date_filters_issued_at_1i"
      click_button "Filter"
      expect(page).to have_css("table tbody tr", count: 3)
      select "February", from: "date_filters_issued_at_2i"
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
      @organization.reload
    end

    context "via manual entry" do
      before(:each) do
        visit @url_prefix + "/donations/new"
      end

      scenario "User can create a donation IN THE PAST" do
        select Donation::SOURCES[:misc], from: "donation_source"
        select StorageLocation.first.name, from: "donation_storage_location_id"
        select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
        fill_in "donation_line_items_attributes_0_quantity", with: "5"
        fill_in "donation_issued_at", with: "01/01/2001"

        expect do
          click_button "Create Donation"
        end.to change { Donation.count }.by(1)

        expect(Donation.last.issued_at).to eq(Date.parse("01/01/2001"))
      end

      scenario "multiple line items for the same item type are accepted and combined on the backend" do
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
          click_button "Create Donation"
        end.to change { Donation.count }.by(1)

        expect(Donation.last.line_items.first.quantity).to eq(15)
      end

      scenario "User can create a donation for a Diaper Drive source" do
        select Donation::SOURCES[:diaper_drive], from: "donation_source"
        expect(page).to have_xpath("//select[@id='donation_diaper_drive_participant_id']")
        expect(page).not_to have_xpath("//select[@id='donation_donation_site_id']")
        select DiaperDriveParticipant.first.name, from: "donation_diaper_drive_participant_id"
        select StorageLocation.first.name, from: "donation_storage_location_id"
        select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
        fill_in "donation_line_items_attributes_0_quantity", with: "5"

        expect do
          click_button "Create Donation"
        end.to change { Donation.count }.by(1)
      end

      scenario "User can create a Diaper Drive from donation" do
        select Donation::SOURCES[:diaper_drive], from: "donation_source"
        select "---Create new diaper drive---", from: "donation_diaper_drive_participant_id"
        expect(page).to have_content("New Diaper Drive Participant")
        fill_in "diaper_drive_participant_name", with: "test"
        fill_in "diaper_drive_participant_email", with: "123@mail.ru"
        click_button "Create Diaper drive participant"
        select "test", from: "donation_diaper_drive_participant_id"
      end

      scenario "User can create a donation for a Donation Site source" do
        select Donation::SOURCES[:donation_site], from: "donation_source"
        expect(page).to have_xpath("//select[@id='donation_donation_site_id']")
        expect(page).not_to have_xpath("//select[@id='donation_diaper_drive_participant_id']")
        select DonationSite.first.name, from: "donation_donation_site_id"
        select StorageLocation.first.name, from: "donation_storage_location_id"
        select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
        fill_in "donation_line_items_attributes_0_quantity", with: "5"

        expect do
          click_button "Create Donation"
        end.to change { Donation.count }.by(1)
      end

      scenario "User can create a donation for Purchased Supplies" do
        select Donation::SOURCES[:misc], from: "donation_source"
        expect(page).not_to have_xpath("//select[@id='donation_donation_site_id']")
        expect(page).not_to have_xpath("//select[@id='donation_diaper_drive_participant_id']")
        select StorageLocation.first.name, from: "donation_storage_location_id"
        select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
        fill_in "donation_line_items_attributes_0_quantity", with: "5"

        expect do
          click_button "Create Donation"
        end.to change { Donation.count }.by(1)
      end

      scenario "User can create a donation with a Miscellaneous source" do
        select Donation::SOURCES[:misc], from: "donation_source"
        expect(page).not_to have_xpath("//select[@id='donation_donation_site_id']")
        expect(page).not_to have_xpath("//select[@id='donation_diaper_drive_participant_id']")
        select StorageLocation.first.name, from: "donation_storage_location_id"
        select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
        fill_in "donation_line_items_attributes_0_quantity", with: "5"

        expect do
          click_button "Create Donation"
        end.to change { Donation.count }.by(1)
      end

      # Since the form only shows/hides the irrelevant field, if the user already selected something it would still
      # submit. The app should sanitize this so we aren't saving extraneous data
      scenario "extraneous data is stripped if the user adds both donation_site and diaper_drive_participant" do
        select Donation::SOURCES[:donation_site], from: "donation_source"
        select DonationSite.first.name, from: "donation_donation_site_id"
        select Donation::SOURCES[:diaper_drive], from: "donation_source"
        select DiaperDriveParticipant.first.name, from: "donation_diaper_drive_participant_id"
        select StorageLocation.first.name, from: "donation_storage_location_id"
        select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
        fill_in "donation_line_items_attributes_0_quantity", with: "5"
        click_button "Create Donation"
        donation = Donation.last
        expect(donation.diaper_drive_participant_id).to be_present
        expect(donation.donation_site_id).to be_nil
      end

      # Bug fix -- Issue #71
      # When a user creates a donation without it passing validation, the items
      # dropdown is not populated on the return trip.
      scenario "items dropdown is still repopulated even if initial submission doesn't validate" do
        item_count = @organization.items.count + 1 # Adds 1 for the "choose an item" option
        expect(page).to have_xpath("//select[@id='donation_line_items_attributes_0_item_id']/option", count: item_count)
        click_button "Create Donation"

        expect(page).to have_content("error")
        expect(page).to have_xpath("//select[@id='donation_line_items_attributes_0_item_id']/option", count: item_count)
      end
    end

    context "via barcode entry" do
      before(:each) do
        initialize_barcodes
        visit @url_prefix + "/donations/new"
      end

      scenario "a user can add items via scanning them in by barcode", :js do
        # enter the barcode into the barcode field

        within "#donation_line_items" do
          expect(page).to have_xpath("//input[@id='_barcode-lookup-0']")
          fill_in "_barcode-lookup-0", with: @existing_barcode.value + 10.chr
        end
        # the form should update
        # save_and_open_page
        expect(page).to have_xpath('//input[@id="donation_line_items_attributes_0_quantity"]')
        expect(page.has_select?("donation_line_items_attributes_0_item_id", selected: @existing_barcode.item.name)).to eq(true)
        qty = page.find(:xpath, '//input[@id="donation_line_items_attributes_0_quantity"]').value

        expect(qty).to eq(@existing_barcode.quantity.to_s)
      end

      scenario "User scan same barcode 2 times", :js do
        within "#donation_line_items" do
          expect(page).to have_xpath("//input[@id='_barcode-lookup-0']")
          fill_in "_barcode-lookup-0", with: @existing_barcode.value + 10.chr
        end

        expect(page).to have_field "donation_line_items_attributes_0_quantity", with: @existing_barcode.quantity.to_s

        within "#donation_line_items" do
          expect(page).to have_xpath("//input[@id='_barcode-lookup-1']")
          fill_in "_barcode-lookup-1", with: @existing_barcode.value + 10.chr
        end

        expect(page).to have_field "donation_line_items_attributes_0_quantity", with: (@existing_barcode.quantity * 2).to_s
      end

      scenario "a user can add items that do not yet have a barcode" do
        # enter a new barcode
        # form finds no barcode and responds by prompting user to choose an item and quantity
        # fill that in
        # saves new barcode
        # form updates
        pending "TODO: adding items with a new barcode"
        raise
      end
    end
  end
end
