require 'ostruct'

RSpec.describe "Dashboard", type: :system, js: true do
  context "With a new essentials bank" do
    before :each do
      @new_organization = create(:organization)
      @user = create(:user, organization: @new_organization)
      @org_short_name = new_organization.short_name
    end
    attr_reader :new_organization, :org_short_name, :user

    before do
      sign_in(user)
    end

    it "displays the getting started guide until the steps are completed" do
      org_dashboard_page = OrganizationDashboardPage.new org_short_name: org_short_name
      org_dashboard_page.visit

      # rubocop:disable Layout/ExtraSpacing

      # When dashboard loads, ensure that we are on step 1 (Partner Agencies)
      expect(org_dashboard_page).to     have_getting_started_guide
      expect(org_dashboard_page).to     have_add_partner_call_to_action
      expect(org_dashboard_page).not_to have_add_storage_location_call_to_action
      expect(org_dashboard_page).not_to have_add_donation_site_call_to_action
      expect(org_dashboard_page).not_to have_add_inventory_call_to_action

      # After we create a partner, ensure that we are on step 2 (Storage Locations)
      @partner = create(:partner, organization: new_organization)
      org_dashboard_page.visit

      expect(org_dashboard_page).to     have_getting_started_guide
      expect(org_dashboard_page).not_to have_add_partner_call_to_action
      expect(org_dashboard_page).to     have_add_storage_location_call_to_action
      expect(org_dashboard_page).not_to have_add_donation_site_call_to_action
      expect(org_dashboard_page).not_to have_add_inventory_call_to_action

      # After we create a storage location, ensure that we are on step 3 (Donation Site)
      create(:storage_location, organization: new_organization)
      org_dashboard_page.visit

      expect(org_dashboard_page).to     have_getting_started_guide
      expect(org_dashboard_page).not_to have_add_partner_call_to_action
      expect(org_dashboard_page).not_to have_add_storage_location_call_to_action
      expect(org_dashboard_page).to     have_add_donation_site_call_to_action
      expect(org_dashboard_page).not_to have_add_inventory_call_to_action

      # After we create a donation site, ensure that we are on step 4 (Inventory)
      create(:donation_site, organization: new_organization)
      org_dashboard_page.visit

      expect(org_dashboard_page).to     have_getting_started_guide
      expect(org_dashboard_page).not_to have_add_partner_call_to_action
      expect(org_dashboard_page).not_to have_add_storage_location_call_to_action
      expect(org_dashboard_page).not_to have_add_donation_site_call_to_action
      expect(org_dashboard_page).to     have_add_inventory_call_to_action

      # rubocop:enable Layout/ExtraSpacing

      # After we add inventory to a storage location, ensure that the getting starting guide is gone
      create(:storage_location, :with_items, item_quantity: 125, organization: new_organization)
      org_dashboard_page.visit

      expect(org_dashboard_page).not_to have_getting_started_guide
    end
  end

  context "With an existing essentials bank" do
    before do
      sign_in(@user)
    end

    let!(:storage_location) { create(:storage_location, :with_items, item_quantity: 0, organization: @organization) }
    let(:org_short_name) { @organization.short_name }
    let(:org_dashboard_page) { OrganizationDashboardPage.new org_short_name: org_short_name }

    describe "Signage" do
      it "shows their organization name unless they have a logo set" do
        org_dashboard_page.visit

        expect(org_dashboard_page).to have_organization_logo

        logo_filename = File.basename(org_dashboard_page.organization_logo_filepath).split("?").first
        expect(logo_filename).to include("logo.jpg")

        # This allows us to simulate the deletion of the org logo without actually deleting it
        # See @awwaiid 's comment: https://github.com/rubyforgood/human-essentials/pull/3220#issuecomment-1297049810
        allow_any_instance_of(Organization).to receive_message_chain(:logo, :attached?).and_return(false)
        org_dashboard_page.visit

        expect(org_dashboard_page).not_to have_organization_logo
      end
    end

    describe "Inventory Totals" do
      describe "Summary" do
        before do
          create_list(:storage_location, 3, :with_items, item_quantity: 111, organization: @organization)
          org_dashboard_page.visit
        end

        it "displays the on-hand totals" do
          expect(org_dashboard_page.summary_section.text).to include "on-hand"
        end

        context "when constrained to date range" do
          it "does not change" do
            expect { org_dashboard_page.select_date_filter_range "Last Month" }
              .not_to change { org_dashboard_page.total_inventory }
              .from 333
          end
        end
      end
    end

    test_time = Time.zone.now

    # 1, 20, 300, ..., 900000000
    # assuming each value is used once, summing these values makes easily recognizable totals
    # .fetch() from it so too-high indices raise IndexError
    # legal indices are in -8..8 (i.e., inclusive)
    item_quantities = (1..9).map { |i| i * 10**(i - 1) }

    describe "Donations" do
      it "has a link to create a new donation" do
        org_new_donation_page = OrganizationNewDonationPage.new org_short_name: org_short_name

        org_dashboard_page.visit

        expect { org_dashboard_page.create_new_donation }
          .to change { page.current_path }
          .to org_new_donation_page.path
      end

      # as of 28 Jan 2022, the "Recent Donations" list shows up to this many items matching the date filter
      max_recent_donation_links_count = 3

      # Make up to this many (inclusive) donations for each filtered period
      # Keep it below (item_quantities.size - 1) so there's at least 2 values left for
      # Donations outside of the filtered period
      max_donations_in_filtered_period = max_recent_donation_links_count + 1

      around do |example|
        # Ensure "today" doesn't change for the server side during the example run
        # Note, however, that this does *not* affect the client side
        # So "today" for the server still might be "yesterday"
        # —possibly even "last month" or "last year"-
        # for the client
        # Rely on rerun via rspec-retry for those edge cases
        travel_to(test_time)
        example.run
        travel_back
      end

      [
        # rubocop:disable Layout/ExtraSpacing, Layout/SpaceAroundOperators
        [nil, test_time -   2.years,                   test_time - rand(180).days, :set_custom_dates], # arbitrary values
        ["Today",        test_time,                               test_time],
        ["Yesterday",    test_time.yesterday,                     test_time.yesterday],
        ["Last 7 Days",  test_time -  6.days,                     test_time],
        ["Last 30 Days", test_time - 29.days,                     test_time],
        ["This Month",   test_time.beginning_of_month,            test_time.end_of_month],
        ["Last Month",   test_time.last_month.beginning_of_month, test_time.last_month.end_of_month],
        ["This Year",    test_time.beginning_of_year,             test_time.end_of_year],
        ["All Time",     test_time - 100.years,                   test_time]
        # rubocop:enable Layout/ExtraSpacing, Layout/SpaceAroundOperators
      ].each do |date_range_info|
        filtered_date_range_label, start_date, end_date, set_custom_dates = date_range_info

        filtered_date_range = start_date.to_date..end_date.to_date
        before_filtered_date_range = start_date.yesterday.to_date
        after_filtered_date_range = end_date.tomorrow.to_date

        start_date_formatted, end_date_formatted = [start_date, end_date].map { _1.to_formatted_s(:date_picker) }

        # Ideally different date ranges get different counts (incl. 0!) to test the various combinations
        # w/out making a fixed pattern
        num_donations_in_filtered_period = rand(0..max_donations_in_filtered_period)

        context "given 1 Donation on #{before_filtered_date_range}, " \
                "#{num_donations_in_filtered_period} during #{filtered_date_range}, and " \
                "1 on #{after_filtered_date_range}" do
          custom_dates = if set_custom_dates
            "#{start_date_formatted} - #{end_date_formatted}"
          end

          before do
            filtered_dates = filtered_date_range.to_a
            @quantities_donated_in_filtered_date_range = []

            @item_quantity = item_quantities.to_enum

            def create_next_donation(donation_date:)
              quantity_in_donation = @item_quantity.next
              create :donation, :with_items, issued_at: donation_date, item_quantity: quantity_in_donation, storage_location: storage_location, organization: @organization

              quantity_in_donation
            end

            # days_this_year.sample in num_donations_in_filtered_period.times loop
            # rather than
            # days_this_year.sample(num_donations_in_filtered_period).each
            # because Array#sample(n) on an Array with m<n elements returns only m elements
            num_donations_in_filtered_period.times do
              @quantities_donated_in_filtered_date_range << create_next_donation(donation_date: filtered_dates.sample)
            end

            # create Donations before & after the filtered date range
            [before_filtered_date_range, after_filtered_date_range].each { create_next_donation donation_date: _1 }
          end

          describe("filtering to '#{filtered_date_range_label}'" + (set_custom_dates ? " (#{custom_dates})" : "")) do
            before do
              org_dashboard_page
                .visit
                .filter_to_date_range(filtered_date_range_label, custom_dates)
            end

            expected_recent_donation_links_count = [max_recent_donation_links_count, num_donations_in_filtered_period].min

            it "shows the correct total and #{expected_recent_donation_links_count} Recent Donation link(s)" do
              expect(org_dashboard_page.total_donations).to eq @quantities_donated_in_filtered_date_range.sum

              recent_donation_links = org_dashboard_page.recent_donation_links

              expect(recent_donation_links.count).to eq expected_recent_donation_links_count

              # Expect the links to be something like "1 item...", "4,000 items from Manufacturer"
              # Strip out the item counts
              recent_quantities = recent_donation_links.map { _1.match(/[0-9,]+/).to_s.delete(",").to_i }

              # By design, the setup may have created more Donations during the period than are visible in the Recent Donation links
              # Make sure each Recent Donation link uniquely matches a single Donation
              expect(@quantities_donated_in_filtered_date_range.intersection(recent_quantities)).to match_array recent_quantities
            end
          end
        end
      end
    end

    describe "Purchases" do
      it "has a link to create a new purchase" do
        org_new_purchase_page = OrganizationNewPurchasePage.new org_short_name: org_short_name

        org_dashboard_page.visit

        expect { org_dashboard_page.create_new_purchase }
          .to change { page.current_path }
          .to org_new_purchase_page.path
      end

      # as of 28 Jan 2022, the "Recent Purchases" list shows up to this many items matching the date filter
      max_recent_purchase_links_count = 3

      # Make up to this many (inclusive) purchases for each filtered period
      # Keep it below (item_quantities.size - 1) so there's at least 2 values left for
      # Purchases outside of the filtered period
      max_purchases_in_filtered_period = max_recent_purchase_links_count + 1

      around do |example|
        # Ensure "today" doesn't change for the server side during the example run
        # Note, however, that this does *not* affect the client side
        # So "today" for the server still might be "yesterday"
        # —possibly even "last month" or "last year"-
        # for the client
        # Rely on rerun via rspec-retry for those edge cases
        travel_to(test_time)
        example.run
        travel_back
      end

      [
        # rubocop:disable Layout/ExtraSpacing, Layout/SpaceAroundOperators
        ["Today",        test_time,                               test_time],
        ["Yesterday",    test_time.yesterday,                     test_time.yesterday],
        ["Last 7 Days",  test_time -  6.days,                     test_time],
        ["Last 30 Days", test_time - 29.days,                     test_time],
        ["This Month",   test_time.beginning_of_month,            test_time.end_of_month],
        ["Last Month",   test_time.last_month.beginning_of_month, test_time.last_month.end_of_month],
        ["This Year",    test_time.beginning_of_year,             test_time.end_of_year],
        ["All Time",     test_time - 100.years,                   test_time],
        [nil, test_time -   2.years,                   test_time - rand(180).days, :set_custom_dates] # arbitrary values
        # rubocop:enable Layout/ExtraSpacing, Layout/SpaceAroundOperators
      ].each do |date_range_info|
        filtered_date_range_label, start_date, end_date, set_custom_dates = date_range_info

        filtered_date_range = start_date.to_date..end_date.to_date
        before_filtered_date_range = start_date.yesterday.to_date
        after_filtered_date_range = end_date.tomorrow.to_date

        start_date_formatted, end_date_formatted = [start_date, end_date].map { _1.to_formatted_s(:date_picker) }

        # Ideally different date ranges get different counts (incl. 0!) to test the various combinations
        # w/out making a fixed pattern
        num_purchases_in_filtered_period = rand(0..max_purchases_in_filtered_period)

        context "given 1 Purchase on #{before_filtered_date_range}, " \
                "#{num_purchases_in_filtered_period} during #{filtered_date_range}, and " \
                "1 on #{after_filtered_date_range}" do
          custom_dates = if set_custom_dates
            "#{start_date_formatted} - #{end_date_formatted}"
          end

          before do
            filtered_dates = filtered_date_range.to_a
            @quantities_donated_in_filtered_date_range = []

            @item_quantity = item_quantities.to_enum

            def create_next_purchase(purchase_date:)
              quantity_in_purchase = @item_quantity.next
              create :purchase, :with_items, issued_at: purchase_date, item_quantity: quantity_in_purchase, storage_location: storage_location, organization: @organization

              quantity_in_purchase
            end

            # days_this_year.sample in num_purchases_in_filtered_period.times loop
            # rather than
            # days_this_year.sample(num_purchases_in_filtered_period).each
            # because Array#sample(n) on an Array with m<n elements returns only m elements
            num_purchases_in_filtered_period.times do
              @quantities_donated_in_filtered_date_range << create_next_purchase(purchase_date: filtered_dates.sample)
            end

            # create Purchases before & after the filtered date range
            [before_filtered_date_range, after_filtered_date_range].each { create_next_purchase purchase_date: _1 }
          end

          describe("filtering to '#{filtered_date_range_label}'" + (set_custom_dates ? " (#{custom_dates})" : "")) do
            before do
              org_dashboard_page
                .visit
                .filter_to_date_range(filtered_date_range_label, custom_dates)
            end

            expected_recent_purchase_links_count = [max_recent_purchase_links_count, num_purchases_in_filtered_period].min

            it "shows correct #{expected_recent_purchase_links_count} Recent Purchase link(s)" do
              recent_purchase_links = org_dashboard_page.recent_purchase_links

              expect(recent_purchase_links.count).to eq expected_recent_purchase_links_count

              # Expect the links to be something like "1 item...", "4,000 items from Manufacturer"
              # Strip out the item counts
              recent_quantities = recent_purchase_links.map { _1.match(/[0-9,]+/).to_s.delete(",").to_i }

              # By design, the setup may have created more Purchases during the period than are visible in the Recent Purchase links
              # Make sure each Recent Purchase link uniquely matches a single Purchase
              expect(@quantities_donated_in_filtered_date_range.intersection(recent_quantities)).to match_array recent_quantities
            end
          end
        end
      end
    end

    describe "Product Drives" do
      around do |example|
        travel_to(test_time)
        example.run
        travel_back
      end

      it "has a widget for product drive summary data" do
        org_dashboard_page.visit

        expect(org_dashboard_page).to have_product_drives_section
      end

      # as of 28 Jan 2022, the "Recent Donations" list shows up to this many items matching the date filter
      max_recent_donation_links_count = 3

      # Make up to this many (inclusive) donations for each filtered period
      # Keep it below (item_quantities.size - 1) so there's at least 2 values left for
      # Donations outside of the filtered period
      max_donations_in_filtered_period = max_recent_donation_links_count + 1

      def create_next_product_drive_donation(donation_date:)
        quantity_in_donation = @item_quantity.next
        drive = @product_drives.sample

        create :product_drive_donation, :with_items, product_drive: drive.drive, product_drive_participant: @product_drive_participant, issued_at: donation_date, item_quantity: quantity_in_donation, storage_location: storage_location, organization: @organization,
          money_raised: @money_raised_on_each_product_drive

        OpenStruct.new drive_name: drive.name, quantity: quantity_in_donation, money_raised: @money_raised_on_each_product_drive
      end

      [
        # rubocop:disable Layout/ExtraSpacing, Layout/SpaceAroundOperators
        ["Today",        test_time,                               test_time],
        ["Yesterday",    test_time.yesterday,                     test_time.yesterday],
        ["Last 7 Days",  test_time -  6.days,                     test_time],
        ["Last 30 Days", test_time - 29.days,                     test_time],
        ["This Month",   test_time.beginning_of_month,            test_time.end_of_month],
        ["Last Month",   test_time.last_month.beginning_of_month, test_time.last_month.end_of_month],
        ["This Year",    test_time.beginning_of_year,             test_time.end_of_year],
        ["All Time",     test_time - 100.years,                   test_time],
        [nil, test_time - 2.years,                     test_time - rand(180).days, :set_custom_dates] # arbitrary values
        # rubocop:enable Layout/ExtraSpacing, Layout/SpaceAroundOperators
      ].each do |date_range_info|
        filtered_date_range_label, start_date, end_date, set_custom_dates = date_range_info

        filtered_date_range = start_date.to_date..end_date.to_date
        before_filtered_date_range = start_date.yesterday.to_date
        after_filtered_date_range = end_date.tomorrow.to_date

        start_date_formatted, end_date_formatted = [start_date, end_date].map { _1.to_formatted_s(:date_picker) }

        # Ideally different date ranges get different counts (incl. 0!) to test the various combinations
        # w/out making a fixed pattern
        num_donations_in_filtered_period = rand(0..max_donations_in_filtered_period)

        context "given 1 Donation on #{before_filtered_date_range}, " \
                "#{num_donations_in_filtered_period} during #{filtered_date_range}, and " \
                "1 on #{after_filtered_date_range}" do
          custom_dates = if set_custom_dates
            "#{start_date_formatted} - #{end_date_formatted}"
          end

          before do
            filtered_dates = filtered_date_range.to_a

            @item_quantity = item_quantities.to_enum
            @money_raised_on_each_product_drive = 123 # This is arbitrary, but needs to be different than other donations

            # Create some number of Product Drives
            # Keep local copy of names so examples can create expected values
            # without relying on fetching info from production code
            @product_drives = (1..rand(2..5)).map do
              name = "Product Drive #{_1}"
              OpenStruct.new name: name, drive: create(:product_drive, name: name)
            end

            # days_this_year.sample in num_donations_in_filtered_period.times loop
            # rather than
            # days_this_year.sample(num_donations_in_filtered_period).each
            # because Array#sample(n) on an Array with m<n elements returns only m elements
            @donations_in_filtered_date_range = num_donations_in_filtered_period.times.map do
              create_next_product_drive_donation donation_date: filtered_dates.sample
            end

            # create Donations before & after the filtered date range
            [before_filtered_date_range, after_filtered_date_range].each { create_next_product_drive_donation donation_date: _1 }
          end

          describe("filtering to '#{filtered_date_range_label}'" + (set_custom_dates ? " (#{custom_dates})" : "")) do
            before do
              org_dashboard_page
                .visit
                .filter_to_date_range(filtered_date_range_label, custom_dates)
            end

            expected_recent_donation_links_count = [max_recent_donation_links_count, num_donations_in_filtered_period].min

            it "shows the correct total donations" do
              expect(org_dashboard_page.product_drive_total_donations).to eq @donations_in_filtered_date_range.map(&:quantity).sum
            end

            it "shows the correct total money raised" do
              expect(org_dashboard_page.product_drive_total_money_raised).to eq @donations_in_filtered_date_range.map(&:money_raised).sum
            end

            it "shows #{expected_recent_donation_links_count} Recent Donation link(s)" do
              recent_donation_links = org_dashboard_page.recent_product_drive_donation_links

              expect(recent_donation_links.count).to eq expected_recent_donation_links_count

              # Expect the links to be something like "1 from Some Drive", "4,000 items from Another Drive"
              # Strip out the item counts & drive names
              recent_donations = recent_donation_links.map do
                items_donated, drive_name = _1.match(/([0-9,]+) from (.+)/).captures

                # e.g., [1, "Some Drive"], [20, "Another Drive"]
                OpenStruct.new quantity: items_donated.delete(",").to_i, drive_name: drive_name, money_raised: @money_raised_on_each_product_drive
              end

              # By design, the setup may have created more Donations during the period than are visible in the Recent Donation links
              # Make sure each Recent Donation link uniquely matches a single Donation
              expect(@donations_in_filtered_date_range.intersection(recent_donations)).to match_array recent_donations
            end
          end
        end
      end

      describe "Product drive behaviour with Mixed Donation types" do
        before do
          @item_quantity = item_quantities.to_enum
          @money_raised_on_each_product_drive = 123 # This is arbitrary, but needs to be different than other donations
          @money_raised_on_each_manufacturer_donation = 231 # This is arbitrary, but needs to be different than other donations

          # Create some number of Product Drives
          # Keep local copy of names so examples can create expected values
          # without relying on fetching info from production code
          @product_drives = (1..rand(2..5)).map do
            name = "Product Drive #{_1}"
            OpenStruct.new name: name, drive: create(:product_drive, name: name)
          end

          @product_drive_donations = 2.times.map do
            create_next_product_drive_donation donation_date: test_time
          end

          # create a different donation -- which shouldn't get included in to our totals or shown under product drive
          quantity_in_donation = @item_quantity.next
          manufacturer = create :manufacturer, name: "Manufacturer for product drive test", organization: @organization
          create :manufacturer_donation, :with_items, manufacturer: manufacturer, issued_at: test_time, item_quantity: quantity_in_donation, storage_location: storage_location, organization: @organization, money_raised: @money_raised_on_each_manufacturer_donation

          org_dashboard_page.visit
        end

        it "only counts product drive donations for product drive" do
          expect(org_dashboard_page.product_drive_total_donations).to eq @product_drive_donations.map(&:quantity).sum
        end

        it "only counts product drive money raised" do
          expect(org_dashboard_page.product_drive_total_money_raised).to eq @product_drive_donations.map(&:money_raised).sum
        end

        it "only shows product drive donations as product drive donations" do
          recent_donation_links = org_dashboard_page.recent_product_drive_donation_links

          expect(recent_donation_links.count).to eq @product_drive_donations.count

          recent_donations = recent_donation_links.map do
            items_donated, drive_name = _1.match(/([0-9,]+) from (.+)/).captures

            # e.g., [1, "Some Drive"], [20, "Another Drive"]
            OpenStruct.new quantity: items_donated.delete(",").to_i, drive_name: drive_name, money_raised: @money_raised_on_each_product_drive
          end

          # By design, the setup may have created more Donations during the period than are visible in the Recent Donation links
          # Make sure each Recent Donation link uniquely matches a single Donation
          expect(@product_drive_donations.intersection(recent_donations)).to match_array recent_donations
        end
      end
    end

    describe "Manufacturer Donations" do
      around do |example|
        travel_to(test_time)
        example.run
        travel_back
      end

      it "has a link to create a new donation" do
        org_dashboard_page.visit

        expect(org_dashboard_page).to have_manufacturers_section
      end

      # as of 15 Feb 2022, the "Top Manufacturer Donations" list shows up to this many manufacturers
      # which donated during the filtered date range
      max_top_manufacturer_donations_links_count = 10

      # Make donations for up to this many (inclusive) manufacturers for each filtered period
      # Different from other sections because the final list also includes the before- and
      # after-date-range donations
      max_manufacturers_donated_in_filtered_period = max_top_manufacturer_donations_links_count - 1

      [
        # rubocop:disable Layout/ExtraSpacing, Layout/SpaceAroundOperators
        ["Today",        test_time,                               test_time],
        ["Yesterday",    test_time.yesterday,                     test_time.yesterday],
        ["Last 7 Days",  test_time -  6.days,                     test_time],
        ["Last 30 Days", test_time - 29.days,                     test_time],
        ["This Month",   test_time.beginning_of_month,            test_time.end_of_month],
        ["Last Month",   test_time.last_month.beginning_of_month, test_time.last_month.end_of_month],
        ["This Year",    test_time.beginning_of_year,             test_time.end_of_year],
        ["All Time",     test_time - 100.years,                   test_time],
        [nil, test_time -   2.years,                   test_time - rand(180).days, :set_custom_dates] # arbitrary values
        # rubocop:enable Layout/ExtraSpacing, Layout/SpaceAroundOperators
      ].each do |date_range_info|
        filtered_date_range_label, start_date, end_date, set_custom_dates = date_range_info

        filtered_date_range = start_date.to_date..end_date.to_date
        before_filtered_date_range = start_date.yesterday.to_date
        after_filtered_date_range = end_date.tomorrow.to_date

        start_date_formatted, end_date_formatted = [start_date, end_date].map { _1.to_formatted_s(:date_picker) }

        # Ideally different date ranges get different counts (incl. 0!) to test the various combinations
        # w/out making a fixed pattern
        num_manufacturers_donated_in_filtered_period = rand(0..max_manufacturers_donated_in_filtered_period)

        context "given 1 Manufacturer donating on #{before_filtered_date_range}, " \
                "#{num_manufacturers_donated_in_filtered_period} during #{filtered_date_range}, and " \
                "1 on #{after_filtered_date_range}" do
          custom_dates = if set_custom_dates
            "#{start_date_formatted} - #{end_date_formatted}"
          end

          before do
            filtered_dates = filtered_date_range.to_a

            @item_quantity = item_quantities.to_enum

            def create_next_manufacturer_donation(manufacturer:, donation_date:)
              quantity_in_donation = @item_quantity.next

              create :manufacturer_donation, :with_items, manufacturer: manufacturer, issued_at: donation_date, item_quantity: quantity_in_donation, storage_location: storage_location, organization: @organization

              quantity_in_donation
            end

            # Generate new Manufacturers and their in-filtered-date-range donations
            @manufacturer_donations_in_filtered_date_range = num_manufacturers_donated_in_filtered_period.times.map do |index|
              @item_quantity.rewind
              manufacturer_name = "In-date-range Manufacturer #{index}"

              manufacturer = create :manufacturer, name: manufacturer_name, organization: @organization

              # Ensure at least 1 donation in the filtered period
              donation_quantities = rand(1..3).times.map do
                create_next_manufacturer_donation manufacturer: manufacturer, donation_date: filtered_dates.sample
              end

              OpenStruct.new manufacturer_name: manufacturer_name, total_quantity_donated: donation_quantities.sum
            end

            # create Donations before & after the filtered date range
            @item_quantity.rewind
            @manufacturer_donations_outside_filtered_date_range = [
              # rubocop:disable Layout/ExtraSpacing
              ["Before", before_filtered_date_range],
              ["After",   after_filtered_date_range]
              # rubocop:enable Layout/ExtraSpacing
            ].map do
              prefix, date = _1

              manufacturer_name = "#{prefix}-date-range Manufacturer"
              manufacturer = create :manufacturer, name: manufacturer_name, organization: @organization
              quantity_donated = create_next_manufacturer_donation manufacturer: manufacturer, donation_date: date

              OpenStruct.new manufacturer_name: manufacturer_name, total_quantity_donated: quantity_donated
            end
          end

          describe("filtering to '#{filtered_date_range_label}'" + (set_custom_dates ? " (#{custom_dates})" : "")) do
            before do
              org_dashboard_page
                .visit
                .filter_to_date_range(filtered_date_range_label, custom_dates)
            end

            # max_manufacturers_donated_in_filtered_period + 2 because the list includes the before- & after-date-range donations, too
            expected_top_manufacturer_donation_links_count = [max_top_manufacturer_donations_links_count, num_manufacturers_donated_in_filtered_period + 2].min

            it "shows the correct total and #{expected_top_manufacturer_donation_links_count} Top Manufacturer Donation link(s)" do
              # "Total" is filtered by the time period
              expected_total_manufacturer_donations = @manufacturer_donations_in_filtered_date_range.map(&:total_quantity_donated).sum
              expect(org_dashboard_page.manufacturers_total_donations).to eq expected_total_manufacturer_donations

              top_manufacturer_donation_links = org_dashboard_page.top_manufacturer_donation_links

              expect(org_dashboard_page.top_manufacturer_donation_links.count).to eq expected_top_manufacturer_donation_links_count

              # Expect the links to be something like "In-date-range Manufacturer 1 (21)", "In-date-range Manufacturer 2 (4,321)", etc.
              # Strip out the item counts & manufacturer names
              top_manufacturer_donations = top_manufacturer_donation_links.map do
                manufacturer_name, total_donated = _1.match(/(.+) \(([0-9,]+)\)/).captures

                OpenStruct.new manufacturer_name: manufacturer_name, total_quantity_donated: total_donated.delete(",").to_i
              end

              # The Top Donations list is *not* filtered by the time period
              # It can contain both the before- and after-filtered-date-range donations
              all_manufacturer_donations = @manufacturer_donations_in_filtered_date_range + @manufacturer_donations_outside_filtered_date_range

              # By design, the setup may have created more Donations during the period than are visible in the Top Donation links
              # Make sure each Top Donation link uniquely matches a single Donation
              expect(all_manufacturer_donations.intersection(top_manufacturer_donations)).to match_array top_manufacturer_donations
            end
          end
        end
      end
    end

    describe "Distributions" do
      around do |example|
        travel_to(test_time)
        example.run
        travel_back
      end

      it "has a link to create a new distribution" do
        org_new_distribution_page = OrganizationNewDistributionPage.new org_short_name: org_short_name

        expect(org_dashboard_page.visit).to have_distributions_section

        expect { org_dashboard_page.create_new_distribution }
          .to change { page.current_path }
          .to org_new_distribution_page.path
      end

      # as of 28 Jan 2022, the "Recent Donations" list shows up to this many items matching the date filter
      max_recent_distribution_links_count = 3

      # Make up to this many (inclusive) donations for each filtered period
      # Keep it below (item_quantities.size - 1) so there's at least 2 values left for
      # Donations outside of the filtered period
      max_distributions_in_filtered_period = max_recent_distribution_links_count + 1

      [
        # rubocop:disable Layout/ExtraSpacing, Layout/SpaceAroundOperators
        ["Today",        test_time,                               test_time],
        ["Yesterday",    test_time.yesterday,                     test_time.yesterday],
        ["Last 7 Days",  test_time -  6.days,                     test_time],
        ["Last 30 Days", test_time - 29.days,                     test_time],
        ["This Month",   test_time.beginning_of_month,            test_time.end_of_month],
        ["Last Month",   test_time.last_month.beginning_of_month, test_time.last_month.end_of_month],
        ["This Year",    test_time.beginning_of_year,             test_time.end_of_year],
        ["All Time",     test_time - 100.years,                   test_time],
        [nil, test_time -   2.years,                   test_time - rand(180).days, :set_custom_dates] # arbitrary values
        # rubocop:enable Layout/ExtraSpacing, Layout/SpaceAroundOperators
      ].each do |date_range_info|
        filtered_date_range_label, start_date, end_date, set_custom_dates = date_range_info

        filtered_date_range = start_date.to_date..end_date.to_date
        before_filtered_date_range = start_date.yesterday.to_date
        after_filtered_date_range = end_date.tomorrow.to_date

        start_date_formatted, end_date_formatted = [start_date, end_date].map { _1.to_formatted_s(:date_picker) }

        # Ideally different date ranges get different counts (incl. 0!) to test the various combinations
        # w/out making a fixed pattern
        num_distributions_in_filtered_period = rand(0..max_distributions_in_filtered_period)

        context "given 1 Distribution on #{before_filtered_date_range}, " \
                "#{num_distributions_in_filtered_period} during #{filtered_date_range}, and " \
                "1 on #{after_filtered_date_range}" do
          custom_dates = if set_custom_dates
            "#{start_date_formatted} - #{end_date_formatted}"
          end

          before do
            filtered_dates = filtered_date_range.to_a

            @item_quantity = item_quantities.to_enum

            # Create some number of Partners
            # Keep local copy of names so examples can create expected values
            # without relying on fetching info from production code
            @partners = (1..rand(2..5)).map do
              name = "Partner #{_1}"
              OpenStruct.new name: name, partner: create(:partner, name: name, organization: @organization)
            end

            def create_next_product_drive_distribution(date_picker:)
              quantity_in_distribution = @item_quantity.next
              partner = @partners.sample

              create :distribution, :with_items, partner: partner.partner, issued_at: date_picker, item_quantity: quantity_in_distribution, storage_location: storage_location, organization: @organization

              OpenStruct.new partner_name: partner.name, quantity: quantity_in_distribution
            end

            # days_this_year.sample in num_distributions_in_filtered_period.times loop
            # rather than
            # days_this_year.sample(num_distributions_in_filtered_period).each
            # because Array#sample(n) on an Array with m<n elements returns only m elements
            @distributions_in_filtered_date_range = num_distributions_in_filtered_period.times.map do
              create_next_product_drive_distribution date_picker: filtered_dates.sample
            end

            # create Distributions before & after the filtered date range
            [before_filtered_date_range, after_filtered_date_range].each { create_next_product_drive_distribution date_picker: _1 }
          end

          describe("filtering to '#{filtered_date_range_label}'" + (set_custom_dates ? " (#{custom_dates})" : "")) do
            before do
              org_dashboard_page
                .visit
                .filter_to_date_range(filtered_date_range_label, custom_dates)
            end

            expected_recent_distribution_links_count = [max_recent_distribution_links_count, num_distributions_in_filtered_period].min

            it "shows the correct total and #{expected_recent_distribution_links_count} Recent Distribution link(s)" do
              expect(org_dashboard_page.total_distributed).to eq @distributions_in_filtered_date_range.map(&:quantity).sum

              recent_distribution_links = org_dashboard_page.recent_distribution_links

              expect(recent_distribution_links.count).to eq expected_recent_distribution_links_count

              # Expect the links to be something like "1 items distributed to Some Shelter", "4,000 items distributed to Some Shelter"
              # Strip out the item counts & drive names
              recent_distributions = recent_distribution_links.map do
                items_distributed, partner_name = _1.match(/([0-9,]+) items distributed to (.+)/).captures

                # e.g., [1, "Some Drive"], [20, "Another Drive"]
                OpenStruct.new quantity: items_distributed.delete(",").to_i, partner_name: partner_name
              end

              # By design, the setup may have created more Distributions during the period than are visible in the Recent Distribution links
              # Make sure each Recent Distribution link uniquely matches a single Distribution
              expect(@distributions_in_filtered_date_range.intersection(recent_distributions)).to match_array recent_distributions
            end
          end
        end
      end
    end
  end
end
