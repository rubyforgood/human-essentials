RSpec.describe "Donations", type: :system, js: true do
  before do
    @url_prefix = "/#{@organization.short_name}"
  end

  context "When signed in as a normal user" do
    before do
      sign_in @user
    end

    context "When visiting the index page" do
      subject { @url_prefix + "/donations" }

      before do
        create(:donation)
        create(:donation)
        visit subject
      end

      it "Allows User to click to the new donation form" do
        find(".fa-plus").click

        expect(current_path).to eq(new_donation_path(@organization))
        expect(page).to have_content "Start a new donation"
      end

      it "Displays Total quantity on the index page" do
        expect(page.find(:css, "table", visible: true)).to have_content("20")
      end

      it "doesn't die when an inactive item is in a donation" do
        item = create(:item, :active, name: "INACTIVE ITEM")
        create(:donation, :with_items, item: item)
        item.update(active: false)
        item.reload
        expect { visit(@url_prefix + "/donations") }.to_not raise_error
      end
    end

    context "When filtering on the index page" do
      subject { @url_prefix + "/donations" }
      let!(:item) { create(:item) }

      it "Filters by the source" do
        create(:donation)
        create(:donation_site_donation)
        visit subject
        expect(page).to have_css("table tbody tr", count: 2)
        select Donation::SOURCES[:misc], from: "filters_by_source"
        click_button "Filter"
        expect(page).to have_css("table tbody tr", count: 1)
      end

      it "Filters by diaper drives" do
        a = create(:diaper_drive, name: 'A')
        b = create(:diaper_drive, name: "B")
        x = create(:diaper_drive_participant, business_name: "X")
        create(:diaper_drive_donation, diaper_drive: a, diaper_drive_participant: x)
        create(:diaper_drive_donation, diaper_drive: b, diaper_drive_participant: x)
        visit subject
        expect(page).to have_css("table tbody tr", count: 2)
        select a.name, from: "filters_by_diaper_drive"
        click_button "Filter"
        expect(page).to have_css("table tbody tr", count: 1)
      end

      it "Filters by diaper drive participant" do
        x = create(:diaper_drive, name: 'x')
        a = create(:diaper_drive_participant, business_name: "A")
        b = create(:diaper_drive_participant, business_name: "B")
        create(:diaper_drive_donation, diaper_drive: x, diaper_drive_participant: a)
        create(:diaper_drive_donation, diaper_drive: x, diaper_drive_participant: b)
        visit subject
        expect(page).to have_css("table tbody tr", count: 2)
        select a.business_name, from: "filters_by_diaper_drive_participant"
        click_button "Filter"
        expect(page).to have_css("table tbody tr", count: 1)
      end
      it "Filters by manufacturer" do
        a = create(:manufacturer, name: "A")
        b = create(:manufacturer, name: "B")
        create(:manufacturer_donation, manufacturer: a)
        create(:manufacturer_donation, manufacturer: b)
        visit subject
        expect(page).to have_css("table tbody tr", count: 2)
        select a.name, from: "filters_from_manufacturer"
        click_button "Filter"
        expect(page).to have_css("table tbody tr", count: 1)
      end
      it "Filters by donation site" do
        location1 = create(:donation_site, name: "location 1")
        location2 = create(:donation_site, name: "location 2")
        create(:donation, donation_site: location1)
        create(:donation, donation_site: location2)
        visit subject
        select location1.name, from: "filters_from_donation_site"
        click_button "Filter"
        expect(page).to have_css("table tbody tr", count: 1)
      end
      it "Filters by storage location" do
        storage1 = create(:storage_location, name: "storage1")
        storage2 = create(:storage_location, name: "storage2")
        create(:donation, storage_location: storage1)
        create(:donation, storage_location: storage2)
        visit subject
        expect(page).to have_css("table tbody tr", count: 2)
        select storage1.name, from: "filters_at_storage_location"
        click_button "Filter"
        expect(page).to have_css("table tbody tr", count: 1)
      end

      it_behaves_like "Date Range Picker", Donation, "issued_at"

      it "Filters by multiple attributes" do
        storage1 = create(:storage_location, name: "storage1")
        storage2 = create(:storage_location, name: "storage2")
        create(:donation, storage_location: storage1)
        create(:donation, storage_location: storage2)
        create(:donation_site_donation, storage_location: storage1)
        visit subject
        expect(page).to have_css("table tbody tr", count: 3)
        select Donation::SOURCES[:misc], from: "filters_by_source"
        click_button "Filter"
        expect(page).to have_css("table tbody tr", count: 2)
        select storage1.name, from: "filters_at_storage_location"
        click_button "Filter"
        expect(page).to have_css("table tbody tr", count: 1)
      end
    end

    context "When creating a new donation" do
      before do
        create(:item, organization: @organization)
        create(:storage_location, organization: @organization)
        create(:donation_site, organization: @organization)
        create(:diaper_drive, organization: @organization)
        create(:diaper_drive_participant, organization: @organization)
        create(:manufacturer, organization: @organization)
        @organization.reload
      end

      context "Via manual entry" do
        before do
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

          expect(Donation.last.issued_at).to eq(Time.zone.parse("2001-01-01"))
        end

        it "User can create a donation using dollars decimal amount for its money raised" do
          select Donation::SOURCES[:misc], from: "donation_source"
          select StorageLocation.first.name, from: "donation_storage_location_id"
          select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
          fill_in "donation_money_raised_in_dollars", with: "1,234.56"

          expect do
            click_button "Save"
          end.to change { Donation.count }.by(1)

          expect(Donation.last.money_raised_in_dollars).to eq(1234.56)
          expect(Donation.last.money_raised).to eq(123_456)
        end

        it "Accepts and combines multiple line items for the same item type" do
          select Donation::SOURCES[:misc], from: "donation_source"
          select StorageLocation.first.name, from: "donation_storage_location_id"
          select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
          fill_in "donation_line_items_attributes_0_quantity", with: "5"
          page.find(:css, "#__add_line_item").click
          select_id = page.find(:xpath, '//*[@id="donation_line_items"]/section[2]//select')[:id]
          select Item.alphabetized.first.name, from: select_id
          text_id = page.find_all('.donation_line_items_quantity > input').last[:id]
          fill_in text_id, with: "10"

          expect do
            click_button "Save"
          end.to change { Donation.count }.by(1)

          expect(Donation.last.line_items.first.quantity).to eq(15)
        end

        it "Does not include inactive items in the line item fields" do
          item = Item.alphabetized.first

          select StorageLocation.first.name, from: "donation_storage_location_id"
          expect(page).to have_content(item.name)
          select item.name, from: "donation_line_items_attributes_0_item_id"

          item.update(active: false)

          page.refresh
          select StorageLocation.first.name, from: "donation_storage_location_id"
          expect(page).to have_no_content(item.name)
        end

        it "Allows User to create a donation for a Diaper Drive Participant source" do
          select Donation::SOURCES[:diaper_drive], from: "donation_source"
          expect(page).to have_xpath("//select[@id='donation_diaper_drive_participant_id']")
          expect(page).not_to have_xpath("//select[@id='donation_donation_site_id']")
          expect(page).not_to have_xpath("//select[@id='donation_manufacturer_id']")
          select DiaperDrive.first.name, from: "donation_diaper_drive_id"
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
          select "---Create new Diaper Drive---", from: "donation_diaper_drive_id"
          expect(page).to have_content("New Diaper Drive")
          fill_in "diaper_drive_name", with: "drivenametest"
          fill_in "diaper_drive_start_date", with: Time.current
          click_on "diaper_drive_submit"
          select "drivenametest", from: "donation_diaper_drive_id"
        end

        it "Allows User to create a Diaper Drive Participant from donation" do
          select Donation::SOURCES[:diaper_drive], from: "donation_source"
          select "---Create new Participant---", from: "donation_diaper_drive_participant_id"
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
          select DiaperDrive.first.name, from: "donation_diaper_drive_id"
          select DiaperDriveParticipant.first.business_name, from: "donation_diaper_drive_participant_id"
          select StorageLocation.first.name, from: "donation_storage_location_id"
          select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
          fill_in "donation_line_items_attributes_0_quantity", with: "5"

          click_button "Save"
          donation = Donation.last

          expect(donation.diaper_drive).to be_present
          expect(donation.manufacturer_id).to be_nil
          expect(donation.donation_site_id).to be_nil
        end

        # Bug fix -- Issue #71
        # When a user creates a donation without it passing validation, the items
        # dropdown is not populated on the return trip.
        it "Repopulates items dropdown even if initial submission doesn't validate" do
          item_count = @organization.items.count + 1 # Adds 1 for the "choose an item" option
          expect(page).to have_xpath("//select[@id='donation_line_items_attributes_0_item_id']/option", count: item_count + 1)
          click_button "Save"

          expect(page).to have_content("error")
          expect(page).to have_xpath("//select[@id='donation_line_items_attributes_0_item_id']/option", count: item_count + 1)
        end

        # Bug fix -- Issue #526
        it "Ensures Barcode Entry fields have unique ids" do
          page.find(:css, "#__add_line_item").click
          page.find(:css, "#__add_line_item").click
          expect(page).to have_xpath("//input[@id='_barcode-lookup-1']")
          expect(page).to have_xpath("//input[@id='_barcode-lookup-2']")
        end

        it "Verifies unusually large donation quantities", js: true do
          select Donation::SOURCES[:misc], from: "donation_source"
          select StorageLocation.first.name, from: "donation_storage_location_id"
          select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
          fill_in "donation_line_items_attributes_0_quantity", with: "1000000"

          expect do
            accept_confirm do
              click_button "Save"
            end
            # wait for the next page to load
            expect(page).not_to have_xpath("//select[@id='donation_line_items_attributes_0_item_id']")
          end.to change { Donation.count }.by(1)
        end

        it "Displays nested errors" do
          select Donation::SOURCES[:misc], from: "donation_source"
          select StorageLocation.first.name, from: "donation_storage_location_id"
          select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
          fill_in "donation_line_items_attributes_0_quantity", with: "10000000000000000000000"

          expect do
            accept_confirm do
              click_button "Save"
            end
            expect(page).to have_xpath("//select[@id='donation_line_items_attributes_0_item_id']")
          end.not_to change { Donation.count }
          expect(page).to have_content("Start a new donation")
          expect(page).to have_content("must be less than")
        end
      end

      context "Via barcode entry" do
        before do
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

    context "When editing an existing donation" do
      before do
        item = create(:item, organization: @organization, name: "Rare Candy")
        create(:storage_location, organization: @organization)
        create(:donation_site, organization: @organization)
        create(:diaper_drive, organization: @organization)
        create(:diaper_drive_participant, organization: @organization)
        create(:manufacturer, organization: @organization)
        create(:donation, :with_items, item: item, organization: @organization)
        @organization.reload
        visit @url_prefix + "/donations/"
      end

      xit "Allows the user to edit a donation" do
        pending("TODO - write this!")
      end

      it "Does not default a selection if item lookup fails" do
        total_quantity = find("#donation_quantity").text
        expect(total_quantity).to_not eq "0"
        click_on "View"
        expect(page).to have_content "Rare Candy"

        click_on "Make a correction"

        item_select = "#donation_line_items_attributes_0_item_id"
        selected_option_text = find(item_select).find("option[selected]").text
        expect(selected_option_text).to eq "Rare Candy"

        # move the item to another org
        rare_candy = Item.find_by(name: "Rare Candy")
        rare_candy.organization = FactoryBot.create(:organization)
        rare_candy.save!
        page.refresh

        # ensure nothing is pre-selected
        expect(find(item_select)).to have_no_css "option[selected]"
        click_on "Save"

        # TODO: I'm not sure if this is the correct behavior, but
        # removing the line item is a lot more benign than randomly
        # switching the item on it to a different item
        total_quantity = find("#donation_quantity").text
        expect(total_quantity).to eq "0 (Total)"
      end
    end

    context "When viewing an existing donation" do
      before do
        @donation = create(:donation, :with_items)

        visit @url_prefix + "/donations/#{@donation.id}"
      end

      it "does not allow deletion of a donation" do
        expect(page).to_not have_link("Delete")
      end
    end
  end

  context "while signed in as an organization admin" do
    before do
      sign_in(@organization_admin)
    end

    context "When viewing an existing donation" do
      before do
        @donation = create(:donation, :with_items, item_quantity: 1)

        visit @url_prefix + "/donations/#{@donation.id}"
      end

      it "allows deletion of a donation" do
        expect(page).to have_link("Delete")

        accept_confirm do
          click_on "Delete", match: :first
        end

        expect(page).to have_content "Donation #{@donation.id} has been removed!"
        # deleted the only donation, ensure total now reads 0
        expect(page).to have_content "Total 0"
      end
    end
  end
end
