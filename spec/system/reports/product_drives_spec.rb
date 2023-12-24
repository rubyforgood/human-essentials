RSpec.describe "ProductDrives Report", type: :system, js: true do
  let!(:storage_location) { create(:storage_location, :with_items, item_quantity: 0, organization: @organization) }
  let(:org_short_name) { @organization.short_name }
  let(:org_reports_product_drives_page) { OrganizationReportsProductDrivesPage.new org_short_name: org_short_name }

  before do
    @url_prefix = "/#{@organization.short_name}"
  end

  context "When signed in as a normal user" do
    before do
      sign_in @user
    end

    test_time = Time.zone.now

    # 1, 20, 300, ..., 900000000
    # assuming each value is used once, summing these values makes easily recognizable totals
    # .fetch() from it so too-high indices raise IndexError
    # legal indices are in -8..8 (i.e., inclusive)
    item_quantities = (1..9).map { |i| i * 10**(i - 1) }

    describe "Product Drives" do
      around do |example|
        travel_to(test_time)
        example.run
        travel_back
      end

      it "has a widget for product drive summary data" do
        org_reports_product_drives_page.visit

        expect(org_reports_product_drives_page).to have_product_drives_section
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

        #  We now can't test the lower limit of All Time, because the earliest possible date is 2000-01-01
        # ["All Time",     test_time - 100.years,                   test_time],
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

        context "given 1 Product Drive Donation on #{before_filtered_date_range} (unless 'All Time'), " \
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
            @donations_in_filtered_date_range = Array.new(num_donations_in_filtered_period) do
              create_next_product_drive_donation donation_date: filtered_dates.sample
            end

            # create Donations before & after the filtered date range
            valid_bracketing_dates(date_range_info).each { create_next_product_drive_donation donation_date: _1 }
          end

          describe("filtering to '#{filtered_date_range_label}'" + (set_custom_dates ? " (#{custom_dates})" : "")) do
            before do
              org_reports_product_drives_page
                .visit
                .filter_to_date_range(filtered_date_range_label, custom_dates)
            end

            expected_recent_donation_links_count = [max_recent_donation_links_count, num_donations_in_filtered_period].min

            it "shows the correct total donations" do
              expect(org_reports_product_drives_page.product_drive_total_donations).to eq @donations_in_filtered_date_range.map(&:quantity).sum
            end

            it "shows the correct total money raised" do
              expect(org_reports_product_drives_page.product_drive_total_money_raised).to eq @donations_in_filtered_date_range.map(&:money_raised).sum
            end

            it "shows #{expected_recent_donation_links_count} Recent Donation link(s)" do
              recent_donation_links = org_reports_product_drives_page.recent_product_drive_donation_links

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

          @product_drive_donations = Array.new(2) do
            create_next_product_drive_donation donation_date: test_time
          end

          # create a different donation -- which shouldn't get included in to our totals or shown under product drive
          quantity_in_donation = @item_quantity.next
          manufacturer = create :manufacturer, name: "Manufacturer for product drive test", organization: @organization
          create :manufacturer_donation, :with_items, manufacturer: manufacturer, issued_at: test_time, item_quantity: quantity_in_donation, storage_location: storage_location, organization: @organization, money_raised: @money_raised_on_each_manufacturer_donation

          org_reports_product_drives_page.visit
        end

        it "only counts product drive donations for product drive" do
          expect(org_reports_product_drives_page.product_drive_total_donations).to eq @product_drive_donations.map(&:quantity).sum
        end

        it "only counts product drive money raised" do
          expect(org_reports_product_drives_page.product_drive_total_money_raised).to eq @product_drive_donations.map(&:money_raised).sum
        end

        it "only shows product drive donations as product drive donations" do
          recent_donation_links = org_reports_product_drives_page.recent_product_drive_donation_links

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
  end

  def valid_bracketing_dates(date_range_info)
    filtered_date_range_label, start_date, end_date, _set_custom_dates = date_range_info
    before_filtered_date_range = start_date.yesterday.to_date
    after_filtered_date_range = end_date.tomorrow.to_date

    if filtered_date_range_label == "All Time"
      [after_filtered_date_range]
    else
      [before_filtered_date_range, after_filtered_date_range]
    end
  end
end
