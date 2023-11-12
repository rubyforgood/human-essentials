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

          @product_drive_donations = Array.new(2) do
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

    describe "Outstanding Requests" do
      it "has a card" do
        org_dashboard_page.visit
        expect(org_dashboard_page).to have_outstanding_section
      end

      context "when empty" do
        before { org_dashboard_page.visit }

        it "displays a message" do
          expect(org_dashboard_page.outstanding_section).to have_content "No outstanding requests!"
        end

        it "has a See More link" do
          expect(org_dashboard_page.outstanding_requests_link).to have_content "See more"
        end
      end

      context "with a pending request" do
        let!(:request) { create :request, :pending }
        let!(:outstanding_request) do
          org_dashboard_page.visit
          requests = org_dashboard_page.outstanding_requests
          expect(requests.length).to eq 1
          requests.first
        end

        it "displays the date" do
          date = outstanding_request.find "td.date"
          expect(date.text).to eq request.created_at.strftime("%m/%d/%Y")
        end

        it "displays the partner" do
          expect(outstanding_request).to have_content request.partner.name
        end

        it "displays the requestor" do
          expect(outstanding_request).to have_content request.partner_user.name
        end

        it "displays the comment" do
          expect(outstanding_request).to have_content request.comments
        end

        it "links to the request" do
          expect { outstanding_request.find('a').click }
            .to change { page.current_path }
            .to "/#{org_short_name}/requests/#{request.id}"
        end

        it "has a See More link" do
          expect(org_dashboard_page.outstanding_requests_link).to have_content "See more"
        end
      end

      it "does display a started request" do
        create :request, :started
        org_dashboard_page.visit
        expect(org_dashboard_page.outstanding_requests.length).to eq 1
      end

      it "does not display a fulfilled request" do
        create :request, :fulfilled
        org_dashboard_page.visit
        expect(org_dashboard_page.outstanding_requests).to be_empty
      end

      it "does not display a discarded request" do
        create :request, :discarded
        org_dashboard_page.visit
        expect(org_dashboard_page.outstanding_requests).to be_empty
      end

      context "with many pending requests" do
        let(:num_requests) { 50 }
        let(:limit) { 25 }
        before do
          create_list :request, num_requests, :pending
          org_dashboard_page.visit
        end

        it "displays a limited number of requests" do
          expect(org_dashboard_page.outstanding_requests.length).to eq limit
        end

        it "has a link with the number of other requests" do
          expect(org_dashboard_page.outstanding_requests_link).to have_content num_requests - limit
        end
      end
    end

    describe "Partner Approvals" do
      it "has a card" do
        org_dashboard_page.visit
        expect(org_dashboard_page).to have_partner_approvals_section
      end

      context "when empty" do
        it "displays a message" do
          org_dashboard_page.visit
          expect(org_dashboard_page.partner_approvals_section).to have_content "No partners waiting for approval"
        end
      end

      context "with no awaiting partners" do
        let!(:partner) { create :partner, :approved }

        it "still displays the simple message" do
          org_dashboard_page.visit
          expect(org_dashboard_page.partner_approvals_section).to have_content "No partners waiting for approval"
        end
      end

      context "with awaiting partners" do
        let!(:org) { create :organization }
        let!(:user) { create :user, organization: org }
        let!(:partner_to_see1) { create :partner, status: :awaiting_review, organization: org }
        let!(:partner_to_see2) { create :partner, status: :awaiting_review, organization: org }
        let!(:partner_hidden1) { create :partner, status: :approved, organization: org }
        let!(:partner_hidden2) { create :partner, status: :invited, organization: org }

        it "only displays awaiting partners" do
          sign_in user
          org_dashboard_page.visit
          within(org_dashboard_page.partner_approvals_section) do
            [partner_to_see1, partner_to_see2].each do |partner|
              expect(page).to have_content partner.name
              expect(page).to have_content partner.profile.primary_contact_email
              expect(page).to have_content partner.profile.primary_contact_name
              expect(page).to have_link "Review Application", href: partner_path(organization_id: org, id: partner) + "#partner-information"
            end
            [partner_hidden1, partner_hidden2].each do |hidden_partner|
              expect(page).to_not have_content hidden_partner.name
              expect(page).to_not have_content hidden_partner.profile.primary_contact_email
              expect(page).to_not have_content hidden_partner.profile.primary_contact_name
              expect(page).to_not have_link "Review Application", href: partner_path(organization_id: org, id: hidden_partner) + "#partner-information"
            end
          end
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
