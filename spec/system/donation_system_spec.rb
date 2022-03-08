RSpec.describe "Donations", type: :system, js: true do
  before do
    @url_prefix = "/#{@organization.short_name}"
  end

  let(:org_donations_page) { OrganizationDonationsPage.new org_short_name: @organization.short_name }

  context "When signed in as a normal user" do
    before do
      sign_in @user
    end

    describe "The list/index page" do
      it "Allows User to click to the new donation form" do
        org_new_donation_page = OrganizationNewDonationPage.new org_short_name: @organization.short_name

        expect do
          org_donations_page
            .visit
            .create_new_donation
        end
          .to change { page.current_path }
          .to org_new_donation_page.path
      end

      context "With an inactive item in a donation" do
        before do
          item = create(:item, :active, name: "INACTIVE ITEM")
          create(:donation, :with_items, item: item)
          item.update(active: false)
          item.reload
        end

        it "Does not error" do
          expect { org_donations_page.visit }.to_not raise_error
        end
      end

      describe "Filtering by a Donation Source" do
        before(:each) do
          create(:donation)
          create(:donation_site_donation)

          org_donations_page.visit
        end

        it "shows the right number of Donations" do
          expect { org_donations_page.filter_by_source :misc }
            .to change { org_donations_page.donations_count }
            .from(2)
            .to(1)
        end
      end

      describe "Filtering by a Product Drive" do
        let(:some_drive_name) { "A" }
        let(:another_drive_name) { "B" }

        before(:each) do
          a = create(:diaper_drive, name: some_drive_name)
          b = create(:diaper_drive, name: another_drive_name)

          x = create(:diaper_drive_participant)

          create(:diaper_drive_donation, diaper_drive: a, diaper_drive_participant: x)
          create(:diaper_drive_donation, diaper_drive: b, diaper_drive_participant: x)

          org_donations_page.visit
        end

        it "shows the right number of Donations" do
          expect { org_donations_page.filter_by_product_drive some_drive_name }
            .to change { org_donations_page.donations_count }
            .from(2)
            .to(1)
        end
      end

      describe "Filtering by a Product Drive Participant" do
        let(:some_participant_name) { "A" }
        let(:another_participant_name) { "B" }

        before(:each) do
          x = create(:diaper_drive)

          a = create(:diaper_drive_participant, business_name: some_participant_name)
          b = create(:diaper_drive_participant, business_name: another_participant_name)

          create(:diaper_drive_donation, diaper_drive: x, diaper_drive_participant: a)
          create(:diaper_drive_donation, diaper_drive: x, diaper_drive_participant: b)

          org_donations_page.visit
        end

        it "shows the right number of Donations" do
          expect { org_donations_page.filter_by_product_drive_participant some_participant_name }
            .to change { org_donations_page.donations_count }
            .from(2)
            .to(1)
        end
      end

      describe "Filtering by a Manufacturer" do
        let(:some_manufacturer_name) { "A" }
        let(:another_manufacturer_name) { "B" }

        before(:each) do
          a = create(:manufacturer, name: some_manufacturer_name)
          b = create(:manufacturer, name: another_manufacturer_name)

          create(:manufacturer_donation, manufacturer: a)
          create(:manufacturer_donation, manufacturer: b)

          org_donations_page.visit
        end

        it "shows the right number of Donations" do
          expect { org_donations_page.filter_by_manufacturer some_manufacturer_name }
            .to change { org_donations_page.donations_count }
            .from(2)
            .to(1)
        end
      end

      describe "Filtering by a Donation Site" do
        let(:some_location_name) { "location 1" }
        let(:another_location_name) { "location 2" }

        before(:each) do
          location1 = create(:donation_site, name: some_location_name)
          location2 = create(:donation_site, name: another_location_name)

          create(:donation, donation_site: location1)
          create(:donation, donation_site: location2)

          org_donations_page.visit
        end

        it "shows the right number of Donations" do
          expect { org_donations_page.filter_by_donation_site some_location_name }
            .to change { org_donations_page.donations_count }
            .from(2)
            .to(1)
        end
      end

      describe "Filtering by a Donation Site" do
        let(:some_storage_location_name) { "storage1" }
        let(:another_storage_location_name) { "storage2" }

        before(:each) do
          storage1 = create(:storage_location, name: some_storage_location_name)
          storage2 = create(:storage_location, name: another_storage_location_name)

          create(:donation, storage_location: storage1)
          create(:donation, storage_location: storage2)

          org_donations_page.visit
        end

        it "shows the right number of Donations" do
          expect { org_donations_page.filter_by_storage_location some_storage_location_name }
            .to change { org_donations_page.donations_count }
            .from(2)
            .to(1)
        end
      end

      describe "Filtering by multiple attributes in succession" do
        let(:some_storage_location_name) { "storage1" }
        let(:another_storage_location_name) { "storage2" }

        before(:each) do
          storage1 = create(:storage_location, name: some_storage_location_name)
          storage2 = create(:storage_location, name: another_storage_location_name)

          create(:donation, storage_location: storage1)
          create(:donation, storage_location: storage2)

          create(:donation_site_donation, storage_location: storage1)

          org_donations_page.visit
        end

        it "Shows the right number of Donations each time" do
          expect { org_donations_page.filter_by_source :misc }
            .to change { org_donations_page.donations_count }
            .from(3)
            .to(2)

          expect { org_donations_page.filter_by_storage_location some_storage_location_name }
            .to change { org_donations_page.donations_count }
            .to(1)
        end
      end
    end

    describe "Creation" do
      before do
        create(:item, organization: @organization)
        create(:storage_location, organization: @organization)
        create(:donation_site, organization: @organization)
        create(:diaper_drive, organization: @organization)
        create(:diaper_drive_participant, organization: @organization)
        create(:manufacturer, organization: @organization)
        @organization.reload
      end

      let(:org_new_donation_page) { OrganizationNewDonationPage.new org_short_name: @organization.short_name }

      context "Via manual entry" do
        before { org_new_donation_page.visit }

        it "Allows donations to be created IN THE PAST" do
          donation_date = Date.new(2001, 2, 13)

          org_new_donation_page
            .set_source(:misc)
            .set_storage_location(StorageLocation.first.name)
            .set_donation_date(donation_date)

          expect { org_new_donation_page.save_donation }
            .to change { Donation.count }
            .by(1)

          expect(page.current_path).to eq org_donations_page.path

          expect(Donation.last.issued_at.to_date).to eq donation_date
        end

        it "Handles money raised using dollars decimal amount" do
          amount_raised = "1,234.56"
          expected_dollars_raised = amount_raised.delete(",").to_f
          expected_money_raised = Integer(expected_dollars_raised * 100)

          org_new_donation_page
            .set_source(:misc)
            .set_storage_location(StorageLocation.first.name)
            .set_money_raised(amount_raised)

          expect { org_new_donation_page.save_donation }
            .to change { Donation.count }
            .by(1)

          expect(page).to have_current_path(org_donations_page.path)

          last_donation = Donation.last
          expect(last_donation.money_raised_in_dollars).to eq(expected_dollars_raised)
          expect(last_donation.money_raised).to eq(expected_money_raised)
        end

        it "Accepts and combines multiple line items for the same item type" do
          item_name = Item.alphabetized.first.name

          # rubocop:disable Layout/ExtraSpacing, Layout/SpaceAroundOperators
          quantity1 =  10
          quantity2 = 200
          # rubocop:enable Layout/ExtraSpacing, Layout/SpaceAroundOperators

          expected_quantity = quantity1 + quantity2

          org_new_donation_page
            .set_source(:misc)
            .set_storage_location(StorageLocation.first.name)
            .set_last_line_item_name(item_name)
            .set_last_line_item_quantity(quantity1)
            .add_line_item
            .set_last_line_item_name(item_name)
            .set_last_line_item_quantity(quantity2)

          expect { org_new_donation_page.save_donation }
            .to change { Donation.count }
            .by(1)

          expect(page.current_path).to eq org_donations_page.path

          expect(Donation.last.line_items.first.quantity).to eq(expected_quantity)
        end

        it "Does not include inactive items in the line item fields" do
          item = Item.alphabetized.first

          org_new_donation_page.set_storage_location(StorageLocation.first.name)

          expect do
            item.update(active: false)
            org_new_donation_page
              .visit
              .set_storage_location(StorageLocation.first.name)
          end
            .to change { org_new_donation_page.item_name_options.include?(item.name) }
            .from(true)
            .to(false)
        end

        fit "Can create ProductDrive Participant Donation" do
          # This passes on CI, but fails routinely on my dev box
          # even when wrapped in
          # using_wait_time(20) do
          # ...
          # end
          # 🤷🏻
          expect { org_new_donation_page.set_source(:diaper_drive) }
            .to change { org_new_donation_page.has_product_drive_participant_select? }
            .from(false)
            .to(true)

          expect(org_new_donation_page).not_to have_donation_site_select
          expect(org_new_donation_page).not_to have_manufacturer_select

          org_new_donation_page
            .set_product_drive(DiaperDrive.first.name)
            .set_product_drive_participant(DiaperDriveParticipant.first.business_name)
            .set_storage_location(StorageLocation.first.name)
            .set_last_line_item_name(Item.alphabetized.first.name)
            .set_last_line_item_quantity(5)

          expect { org_new_donation_page.save_donation }
            .to change { Donation.count }
            .by(1)
        end

        fit "Allows User to create a Product Drive from donation" do
          org_new_donation_page.set_source(:diaper_drive)

          new_product_drive_name = "drivenametest"

          expect(org_new_donation_page.product_drive_name_options)
            .not_to include(new_product_drive_name)

          expect { org_new_donation_page.set_product_drive(:create_new_product_drive) }
            .to change { org_new_donation_page.has_new_product_drive_entry? }
            .from(false)
            .to(true)

          expect do
            org_new_donation_page
              .set_new_product_drive_name(new_product_drive_name)
              .set_new_product_start_date(Time.current)
              .create_new_product_drive
          end
            .to change { org_new_donation_page.has_no_new_product_drive_entry? }
            .to(true)

          expect(org_new_donation_page.product_drive_name_options)
            .to include(new_product_drive_name)
        end

        it "Allows User to create a Product Drive Participant from donation" do
          select Donation::SOURCES[:diaper_drive], from: "donation_source"
          select "---Create new Participant---", from: "donation_diaper_drive_participant_id"
          expect(page).to have_content("New Product Drive Participant")
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
        it "Strips extraneous data if the user adds both Donation Site and Product Drive Participant" do
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

    subject { @url_prefix + "/donations" }
    let!(:item) { create(:item) }

    it_behaves_like "Date Range Picker", Donation, "issued_at"

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

      it "displays donation comment" do
        expect(page).to have_css("#donation-comment")
        within "#donation-comment" do
          expect(page).to have_content("It's a fine day for diapers.")
        end
      end

      context 'when there is no comment defined' do
        before do
          donation = create(:donation, :with_items, comment: nil)
          visit @url_prefix + "/donations/#{donation.id}"
        end

        it 'displays the None provided as the comment ' do
          within "#donation-comment" do
            expect(page).to have_content("None provided")
          end
        end
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
