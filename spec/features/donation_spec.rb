RSpec.feature "Donations", type: :feature, js: true do
  before :each do
    sign_in @user
    @url_prefix = "/#{@organization.short_name}"
  end

  context "When visiting the index page" do
    before(:each) do
      visit @url_prefix + "/donations"
    end

    scenario "User can click to the new donation form" do
      click_link "New Donation"

      expect(current_path).to eq(new_donation_path(@organization))
      expect(page).to have_content "Start a new donation"
    end
  end

  context "When creating a new donation" do
    before(:each) do
      create(:item, organization: @organization)
      create(:storage_location, organization: @organization)
      create(:dropoff_location, organization: @organization)
      create(:diaper_drive_participant, organization: @organization)
      @organization.reload
    end

    context "via manual entry" do
      before(:each) do
        visit @url_prefix + "/donations/new"
      end

      scenario "User can create a donation IN THE PAST" do
        select Donation::SOURCES[:purchased], from: "donation_source"
        select StorageLocation.first.name, from: "donation_storage_location_id"
        select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
        fill_in "donation_line_items_attributes_0_quantity", with: "5"
        fill_in "donation_issued_at", with: "01/01/2001"

        expect {
          click_button "Create Donation"
        }.to change{Donation.count}.by(1)

        expect(Donation.last.issued_at).to eq(Date.parse("01/01/2001"))
      end

      scenario "multiple line items for the same item type are accepted and combined on the backend" do
        select Donation::SOURCES[:purchased], from: "donation_source"
        select StorageLocation.first.name, from: "donation_storage_location_id"
        select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
        fill_in "donation_line_items_attributes_0_quantity", with: "5"
        page.find(:css, "#__add_line_item").click
        select_id = page.find(:xpath, "//div[@id='donation_line_items']/div[2]/div[2]/div[1]/select")[:id]
        select Item.alphabetized.first.name, from: select_id
        text_id = page.find(:xpath, "//div[@id='donation_line_items']/div[2]/div[2]/div[2]/input")[:id]
        fill_in text_id, with: "10"

        expect {
          click_button "Create Donation"
        }.to change{Donation.count}.by(1)

        expect(Donation.last.line_items.first.quantity).to eq(15)

      end

      scenario "User can create a donation for a Diaper Drive source" do
        select Donation::SOURCES[:diaper_drive], from: "donation_source"
        expect(page).to have_xpath("//select[@id='donation_diaper_drive_participant_id']")
        expect(page).not_to have_xpath("//select[@id='donation_dropoff_location_id']")
        select DiaperDriveParticipant.first.name, from: "donation_diaper_drive_participant_id"
        select StorageLocation.first.name, from: "donation_storage_location_id"
        select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
        fill_in "donation_line_items_attributes_0_quantity", with: "5"

        expect {
          click_button "Create Donation"
        }.to change{Donation.count}.by(1)
      end

      scenario "User can create a donation for a Donation Site source" do
        select Donation::SOURCES[:dropoff], from: "donation_source"
        expect(page).to have_xpath("//select[@id='donation_dropoff_location_id']")
        expect(page).not_to have_xpath("//select[@id='donation_diaper_drive_participant_id']")
        select DropoffLocation.first.name, from: "donation_dropoff_location_id"
        select StorageLocation.first.name, from: "donation_storage_location_id"
        select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
        fill_in "donation_line_items_attributes_0_quantity", with: "5"

        expect {
          click_button "Create Donation"
        }.to change{Donation.count}.by(1)
      end

      scenario "User can create a donation for Purchased Supplies" do
        select Donation::SOURCES[:purchased], from: "donation_source"
        expect(page).not_to have_xpath("//select[@id='donation_dropoff_location_id']")
        expect(page).not_to have_xpath("//select[@id='donation_diaper_drive_participant_id']")
        select StorageLocation.first.name, from: "donation_storage_location_id"
        select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
        fill_in "donation_line_items_attributes_0_quantity", with: "5"

        expect {
          click_button "Create Donation"
        }.to change{Donation.count}.by(1)
      end

      scenario "User can create a donation with a Miscellaneous source" do
        select Donation::SOURCES[:misc], from: "donation_source"
        expect(page).not_to have_xpath("//select[@id='donation_dropoff_location_id']")
        expect(page).not_to have_xpath("//select[@id='donation_diaper_drive_participant_id']")
        select StorageLocation.first.name, from: "donation_storage_location_id"
        select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
        fill_in "donation_line_items_attributes_0_quantity", with: "5"

        expect {
          click_button "Create Donation"
        }.to change{Donation.count}.by(1)
      end

      # Since the form only shows/hides the irrelevant field, if the user already selected something it would still
      # submit. The app should sanitize this so we aren't saving extraneous data
      scenario "extraneous data is stripped if the user adds both dropoff_location and diaper_drive_participant" do
        select Donation::SOURCES[:dropoff], from: "donation_source"
        select DropoffLocation.first.name, from: "donation_dropoff_location_id"
        select Donation::SOURCES[:diaper_drive], from: "donation_source"
        select DiaperDriveParticipant.first.name, from: "donation_diaper_drive_participant_id"
        select StorageLocation.first.name, from: "donation_storage_location_id"
        select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
        fill_in "donation_line_items_attributes_0_quantity", with: "5"
        click_button "Create Donation"
        donation = Donation.last
        expect(donation.diaper_drive_participant_id).to be_present
        expect(donation.dropoff_location_id).to be_nil
      end

      # Bug fix -- Issue #71
      # When a user creates a donation without it passing validation, the items
      # dropdown is not populated on the return trip.
      scenario "items dropdown is still repopulated even if initial submission doesn't validate" do
        item_count = @organization.items.count + 1  # Adds 1 for the "choose an item" option
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

      scenario "a user can add items via scanning them in by barcode" do
        pending "The JS doesn't appear to be executing in this correctly"
        # enter the barcode into the barcode field
        expect(page).to have_xpath("//input[@id='_barcode-lookup-0']")
        fill_in "Barcode Entry:", with: @existing_barcode.value + 13.chr
        # the form should update
        #save_and_open_page
        expect(page).to have_xpath('//input[@id="donation_line_items_attributes_0_quantity"]')
        qty = page.find(:xpath, '//input[@id="donation_line_items_attributes_0_quantity"]').value

        expect(qty).to eq(@existing_barcode.quantity.to_s)
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
