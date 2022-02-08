RSpec.describe "Dashboard", type: :system, js: true, skip_seed: true do
  context "With a new Diaper bank" do
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

  context "With an existing Diaper bank" do
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

        @organization.logo.purge
        @organization.save
        org_dashboard_page.visit

        expect(org_dashboard_page).not_to have_organization_logo
      end
    end

    describe "Inventory Totals" do
      test_time = Time.zone.now
      let(:date_to_view) { Time.zone.now }
      let(:last_year_date) { Time.zone.now - 1.year }
      let(:beginning_of_year) { Time.zone.now.beginning_of_year }

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

      describe "Donations" do
        it "has a link to create a new donation" do
          org_new_donation_page = OrganizationNewDonationPage.new org_short_name: org_short_name

          org_dashboard_page.visit

          expect { org_dashboard_page.create_new_donation }
            .to change { page.current_path }
            .to org_new_donation_page.path
        end

        # it "doesn't count inactive items" do
        #   item = create(:donation, :with_items, item_quantity: 100, storage_location: storage_location).items.first
        #
        #   visit subject
        #   within "#donations" do
        #     expect(page).to have_content("100")
        #   end
        #
        #   item.update!(active: false)
        #   visit subject
        #   within "#donations" do
        #     expect(page).to have_no_content("100")
        #   end
        # end

        # 1, 20, 300, ..., 900000000
        # assuming each value is used once, summing these values makes easily recognizable totals
        # .fetch() from it so too-high indices raise IndexError
        # legal indices are in -8..8 (i.e., inclusive)
        item_quantities = (1..9).map { |i| i * 10**(i - 1) }

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
          ["Today",        test_time,                               test_time],
          ["Yesterday",    test_time.yesterday,                     test_time.yesterday],
          ["Last 7 Days",  test_time -  6.days,                     test_time],
          ["Last 30 Days", test_time - 29.days,                     test_time],
          ["This Month",   test_time.beginning_of_month,            test_time.end_of_month],
          ["Last Month",   test_time.last_month.beginning_of_month, test_time.last_month.end_of_month],
          ["This Year",    test_time.beginning_of_year,             test_time.end_of_year],
          ["All Time",     test_time - 100.years,                   test_time],
          ["Custom Range", test_time -   2.years,                   test_time - rand(180).days, :set_custom_dates] # arbitrary values
          # rubocop:enable Layout/ExtraSpacing, Layout/SpaceAroundOperators
        ].each do |date_range_info|
          filtered_date_range_label, start_date, end_date, set_custom_dates = date_range_info

          filtered_date_range = start_date.to_date..end_date.to_date
          before_filtered_date_range = start_date.yesterday.to_date
          after_filtered_date_range = end_date.tomorrow.to_date

          start_date_formatted, end_date_formatted = [start_date, end_date].map { _1.strftime "%m/%d/%y"}

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

                # Expect the links to be something like "1 item...", "20 items from Manufacturer"
                # Strip out the item counts
                recent_quantities = recent_donation_links.map { _1.match(/\d+/).to_s.to_i }

                # By design, the setup may have created more Donations during the period than are visible in the Recent Donation links
                # Make sure each Recent Donation link uniquely matches a single Donation
                expect(@quantities_donated_in_filtered_date_range.intersection(recent_quantities)).to match_array recent_quantities
              end
            end
          end
        end
      end

      describe "Purchases" do
        around do |example|
          travel_to(date_to_view)
          example.run
          travel_back
        end

        it "has a link to create a new purchase" do
          org_new_purchase_page = OrganizationNewPurchasePage.new org_short_name: org_short_name

          org_dashboard_page.visit

          expect { org_dashboard_page.create_new_purchase }
            .to change { page.current_path }
            .to org_new_purchase_page.path
        end

        # it 'does not count inactive items' do
        #   item = create(:purchase, :with_items, item_quantity: 100, storage_location: storage_location).items.first
        #
        #   visit subject
        #   within "#purchases" do
        #     expect(page).to have_content("100")
        #   end
        #
        #   item.update!(active: false)
        #   visit subject
        #   within "#purchases" do
        #     expect(page).to have_no_content("100")
        #   end
        # end

        context "when constrained to date range" do
          before do
            @organization.purchases.destroy_all
            storage_location = create(:storage_location, :with_items, item_quantity: 0, organization: @organization)
            @this_years_purchases = {
              today: create(:purchase, :with_items, issued_at: date_to_view, item_quantity: 100, storage_location: storage_location, organization: @organization),
              yesterday: create(:purchase, :with_items, issued_at: date_to_view.yesterday, item_quantity: 101, storage_location: storage_location, organization: @organization),
              earlier_this_week: create(:purchase, :with_items, issued_at: date_to_view.beginning_of_week, item_quantity: 102, storage_location: storage_location, organization: @organization),
              beginning_of_year: create(:purchase, :with_items, issued_at: beginning_of_year, item_quantity: 103, storage_location: storage_location, organization: @organization)
            }
            @last_years_purchases = create_list(:purchase, 2, :with_items, issued_at: last_year_date, item_quantity: 104, storage_location: storage_location, organization: @organization)
            org_dashboard_page.visit
          end

          describe "This Year" do
            before do
              org_dashboard_page.filter_to_date_range "This Year"
            end

            it "has a widget displaying the year-to-date Purchase totals, only using purchases from this year" do
              recent_purchase_links = org_dashboard_page.recent_purchase_links
              expect(recent_purchase_links).to include(match /100/i)
              expect(recent_purchase_links).to include(match /101/i)
              expect(recent_purchase_links).to include(match /102/i)
            end

            it "displays some recent purchases" do
              expect(org_dashboard_page.recent_purchase_links)
                .to include(match /10\d items/i) # e.g., "101 items", "103 items", etc.
                .exactly(3).times
            end
          end

          describe "Today" do
            before do
              org_dashboard_page.filter_to_date_range "Today"
            end

            let(:total_inventory) { @this_years_purchases[:today].total_quantity }

            it "has a widget displaying today's Purchase totals, only using purchases from today" do
              recent_purchase_links = org_dashboard_page.recent_purchase_links

              # rubocop:disable Layout/ExtraSpacing
              expect(recent_purchase_links).to     include(match /#{total_inventory}/i)
              expect(recent_purchase_links).not_to include(match /101/i)
              # rubocop:enable Layout/ExtraSpacing
            end

            it "displays some recent purchases" do
              expect(org_dashboard_page.recent_purchase_links)
                .to include(match /#{total_inventory}/i)
                .exactly(:once)
            end
          end

          describe "Yesterday" do
            before do
              org_dashboard_page.filter_to_date_range "Yesterday"
            end

            let(:total_inventory) { @this_years_purchases[:yesterday].total_quantity }

            it "has a widget displaying the Purchase totals from yesterday, only using purchases from yesterday" do
              # recent_purchase_links = org_dashboard_page.recent_purchase_links

              # expect(recent_purchase_links).not_to include(match /100/i)
              # expect(recent_purchase_links).to     include(match /#{total_inventory}/i)
              # expect(recent_purchase_links).not_to include(match /102/i)
            end

            it "displays some recent purchases" do
              expect(org_dashboard_page.recent_purchase_links)
                .to include(match /#{total_inventory} items/i)
                .exactly(:once)
            end
          end

          describe "This Week" do
            before do
              org_dashboard_page.filter_to_date_range "Last 7 Days"
            end

            it "has a widget displaying the Purchase totals from this week, only using purchases from this week" do
              recent_purchase_links = org_dashboard_page.recent_purchase_links

              # rubocop:disable Layout/ExtraSpacing
              expect(recent_purchase_links).to     include(match /100/i)
              expect(recent_purchase_links).to     include(match /101/i)
              expect(recent_purchase_links).to     include(match /102/i)

              expect(recent_purchase_links).not_to include(match /103/i)
              expect(recent_purchase_links).not_to include(match /104/i)
              # rubocop:enable Layout/ExtraSpacing
            end

            it "displays some recent purchases" do
              expect(org_dashboard_page.recent_purchase_links)
                .to include(match /10\d items/i) # e.g., "100", "101", etc.
                .exactly(3).times
            end
          end

          describe "This Month" do
            before do
              org_dashboard_page.filter_to_date_range "This Month"
            end

            let(:total_inventory) { @this_years_purchases[:today].total_quantity }

            it "has a widget displaying the Purchase totals from this month, only using purchases from this month" do
              recent_purchase_links = org_dashboard_page.recent_purchase_links

              # rubocop:disable Layout/ExtraSpacing
              expect(recent_purchase_links).to     include(match /100/i)
              expect(recent_purchase_links).to     include(match /101/i)
              expect(recent_purchase_links).to     include(match /102/i)

              expect(recent_purchase_links).not_to include(match /103/i)
              expect(recent_purchase_links).not_to include(match /104/i)
              # rubocop:enable Layout/ExtraSpacing
            end

            it "displays some recent purchases" do
              expect(org_dashboard_page.recent_purchase_links)
                .to include(match /#{total_inventory} items/i)
                .exactly(:once)
            end
          end

          describe "All Time" do
            before do
              org_dashboard_page.filter_to_date_range "All Time"
            end

            it "has a widget displaying the most 3 recent purchases" do
              recent_purchase_links = org_dashboard_page.recent_purchase_links

              # rubocop:disable Layout/ExtraSpacing
              expect(recent_purchase_links).to     include(match /100/i)
              expect(recent_purchase_links).to     include(match /101/i)
              expect(recent_purchase_links).to     include(match /102/i)

              expect(recent_purchase_links).not_to include(match /103/i)
              expect(recent_purchase_links).not_to include(match /104/i)
              # rubocop:enable Layout/ExtraSpacing
            end

            it "displays some recent purchases from that time" do
              expect(org_dashboard_page.recent_purchase_links)
                .to include(match /10\d items/i) # e.g., "100", "101", etc.
                .exactly(3).times
            end
          end
        end
      end

      describe "Diaper Drives" do
        around do |example|
          travel_to(date_to_view)
          example.run
          travel_back
        end

        it "has a widget for diaper drive summary data" do
          org_dashboard_page.visit

          expect(org_dashboard_page).to have_diaper_drives_section
        end

        context "when constrained to date range" do
          before do
            @organization.donations.destroy_all
            storage_location = create(:storage_location, :with_items, item_quantity: 0, organization: @organization)
            diaper_drive1 = create(:diaper_drive, name: 'First Diaper Drive')
            diaper_drive2 = create(:diaper_drive, name: 'Second Diaper Drive')

            diaper_drive_participant1 = create(:diaper_drive_participant, business_name: "First Diaper Participant Drive", organization: @organization)
            diaper_drive_participant2 = create(:diaper_drive_participant, business_name: "Second Diaper Participant Drive", organization: @organization)

            @this_years_donations = {
              today: create(:diaper_drive_donation, :with_items, diaper_drive: diaper_drive1, diaper_drive_participant: diaper_drive_participant1, issued_at: date_to_view, item_quantity: 100, storage_location: storage_location, organization: @organization),
              yesterday: create(:diaper_drive_donation, :with_items, diaper_drive: diaper_drive2, diaper_drive_participant: diaper_drive_participant2, issued_at: date_to_view.yesterday, item_quantity: 101, storage_location: storage_location, organization: @organization),
              earlier_this_week: create(:diaper_drive_donation, :with_items, diaper_drive: diaper_drive1, diaper_drive_participant: diaper_drive_participant1, issued_at: date_to_view.beginning_of_week, item_quantity: 102, storage_location: storage_location, organization: @organization)
              # See https://github.com/rubyforgood/human-essentials/issues/2676#issuecomment-1008166066
              # beginning_of_year: create(:diaper_drive_donation, :with_items, diaper_drive: diaper_drive2, diaper_drive_participant: diaper_drive_participant2, issued_at: beginning_of_year, item_quantity: 103, storage_location: storage_location, organization: @organization)
            }

            @last_years_donations = create_list(:diaper_drive_donation, 2, :with_items, diaper_drive: diaper_drive1, diaper_drive_participant: diaper_drive_participant1, issued_at: last_year_date, item_quantity: 104, storage_location: storage_location, organization: @organization)
            org_dashboard_page.visit
          end

          describe "This Year" do
            before do
              org_dashboard_page.filter_to_date_range "This Year"
            end

            let(:total_inventory) { @this_years_donations.values.map(&:total_quantity).sum }
            let(:today_name) { @this_years_donations[:today].diaper_drive.name }
            let(:yesterday_name) { @this_years_donations[:yesterday].diaper_drive.name }
            let(:week_name) { @this_years_donations[:earlier_this_week].diaper_drive.name }
            # See https://github.com/rubyforgood/human-essentials/issues/2676#issuecomment-1008166066
            # let(:year_name) { @this_years_donations[:beginning_of_year].diaper_drive.name }

            it "has a widget displaying the year-to-date Diaper drive totals, only using donations from this year" do
              recent_diaper_drive_links = org_dashboard_page.recent_diaper_drive_donation_links

              expect(recent_diaper_drive_links).to include(match today_name)
              expect(recent_diaper_drive_links).to include(match yesterday_name)
              expect(recent_diaper_drive_links).to include(match week_name)
              # See https://github.com/rubyforgood/human-essentials/issues/2676#issuecomment-1008166066
              # expect(recent_diaper_drive_links).to include(match year_name)

              expect(org_dashboard_page.diaper_drive_total_donations).to eq total_inventory
            end

            it "displays some recent donations" do
              expect(org_dashboard_page.recent_diaper_drive_donation_links)
                .to include(match /10\d from (first|second) diaper drive/i) # e.g., "101 from ...", "103 from ...", etc.
                .exactly(3).times
            end
          end

          describe "Today" do
            before do
              org_dashboard_page.filter_to_date_range "Today"
            end

            let(:total_inventory) { @this_years_donations[:today].total_quantity }
            let(:name) { @this_years_donations[:today].diaper_drive.name }

            it "has a widget displaying today's Diaper drive totals, only using donations from today" do
              expect(org_dashboard_page.recent_diaper_drive_donation_links).to include(match name)
              expect(org_dashboard_page.diaper_drive_total_donations).to eq total_inventory
            end

            it "displays some recent donations" do
              expect(org_dashboard_page.recent_diaper_drive_donation_links)
                .to include(match /#{total_inventory} from first diaper drive/i)
                .exactly(:once)
            end
          end

          describe "Yesterday" do
            before do
              org_dashboard_page.filter_to_date_range "Yesterday"
            end

            let(:total_inventory) { @this_years_donations[:yesterday].total_quantity }
            let(:name) { @this_years_donations[:yesterday].diaper_drive.name }

            it "has a widget displaying the Diaper drive totals from yesterday, only using donations from yesterday" do
              expect(org_dashboard_page.recent_diaper_drive_donation_links).to include(match name)
              expect(org_dashboard_page.diaper_drive_total_donations).to eq total_inventory
            end

            it "displays some recent donations" do
              expect(org_dashboard_page.recent_diaper_drive_donation_links)
                .to include(match /#{total_inventory} from second diaper drive/i)
                .exactly(:once)
            end
          end

          describe "This Week" do
            before do
              org_dashboard_page.filter_to_date_range "Last 7 Days"
            end

            let(:total_inventory) { [@this_years_donations[:today], @this_years_donations[:yesterday], @this_years_donations[:earlier_this_week]].map(&:total_quantity).sum }
            let(:today_name) { @this_years_donations[:today].diaper_drive.name }
            let(:yesterday_name) { @this_years_donations[:yesterday].diaper_drive.name }
            let(:week_name) { @this_years_donations[:earlier_this_week].diaper_drive.name }

            it "has a widget displaying the Diaper drive totals from this week, only using donations from this week" do
              recent_diaper_drive_links = org_dashboard_page.recent_diaper_drive_donation_links

              expect(recent_diaper_drive_links).to include(match today_name)
              expect(recent_diaper_drive_links).to include(match yesterday_name)
              expect(recent_diaper_drive_links).to include(match week_name)

              expect(org_dashboard_page.diaper_drive_total_donations).to eq total_inventory
            end

            it "displays some recent donations" do
              expect(org_dashboard_page.recent_diaper_drive_donation_links)
                .to include(match /10\d from (first|second) diaper drive/i) # e.g., "101 from ...", "103 from ...", etc.
                .exactly(3).times
            end
          end

          describe "This Month" do
            before do
              org_dashboard_page.filter_to_date_range "This Month"
            end

            let(:total_inventory) { [@this_years_donations[:today], @this_years_donations[:yesterday], @this_years_donations[:earlier_this_week]].map(&:total_quantity).sum }
            let(:today_name) { @this_years_donations[:today].diaper_drive.name }
            let(:yesterday_name) { @this_years_donations[:yesterday].diaper_drive.name }
            let(:week_name) { @this_years_donations[:earlier_this_week].diaper_drive.name }

            it "has a widget displaying the Diaper drive totals from this month, only using donations from this month" do
              recent_diaper_drive_links = org_dashboard_page.recent_diaper_drive_donation_links

              expect(recent_diaper_drive_links).to include(match today_name)
              expect(recent_diaper_drive_links).to include(match yesterday_name)
              expect(recent_diaper_drive_links).to include(match week_name)

              expect(org_dashboard_page.diaper_drive_total_donations).to eq total_inventory
            end

            it "displays some recent donations" do
              expect(org_dashboard_page.recent_diaper_drive_donation_links)
                .to include(match /10\d from (first|second) diaper drive/i) # e.g., "101 from ...", "103 from ...", etc.
                .exactly(3).times
            end
          end

          describe "All Time" do
            before do
              org_dashboard_page.filter_to_date_range "All Time"
            end

            let(:total_inventory) { @this_years_donations.values.map(&:total_quantity).sum + @last_years_donations.map(&:total_quantity).sum }
            let(:today_name) { @this_years_donations[:today].diaper_drive.name }
            let(:yesterday_name) { @this_years_donations[:yesterday].diaper_drive.name }
            let(:week_name) { @this_years_donations[:earlier_this_week].diaper_drive.name }
            # See https://github.com/rubyforgood/human-essentials/issues/2676#issuecomment-1008166066
            # let(:year_name) { @this_years_donations[:beginning_of_year].diaper_drive.name }
            let(:last_year_name) { @last_years_donations[0].diaper_drive.name }

            it "has a widget displaying the Diaper drive totals from last year, only using donations from last year" do
              expect(org_dashboard_page.diaper_drive_total_donations).to eq total_inventory

              recent_diaper_drive_links = org_dashboard_page.recent_diaper_drive_donation_links

              expect(recent_diaper_drive_links).to include(match today_name)
              expect(recent_diaper_drive_links).to include(match yesterday_name)
              expect(recent_diaper_drive_links).to include(match week_name)
              # See https://github.com/rubyforgood/human-essentials/issues/2676#issuecomment-1008166066
              # expect(recent_diaper_drive_links).to include(match year_name)
              expect(recent_diaper_drive_links).to include(match last_year_name)
            end

            it "displays some recent donations from that time" do
              expect(org_dashboard_page.recent_diaper_drive_donation_links)
                .to include(match /10\d from (first|second) diaper drive/i) # e.g., "101 from ...", "103 from ...", etc.
                .exactly(3).times
            end
          end
        end
      end

      describe "Manufacturer Donations" do
        around do |example|
          travel_to(date_to_view)
          example.run
          travel_back
        end

        it "should list top 10 manufacturers" do
          org_dashboard_page.visit

          expect(org_dashboard_page.manufacturers_total_donations).to eq 0
          expect(org_dashboard_page.num_manufacturers_donated).to eq 0

          item_qty = 200
          12.times do
            manufacturer = create(:manufacturer)
            create(:donation, :with_items, item: Item.first, item_quantity: item_qty, source: Donation::SOURCES[:manufacturer], manufacturer: manufacturer, issued_at: Time.zone.today)
            item_qty -= 1
          end

          org_dashboard_page.visit

          expect(org_dashboard_page.manufacturers_total_donations).to eq 2_334
          expect(org_dashboard_page.num_manufacturers_donated).to eq 12
          expect(org_dashboard_page.recent_manufacturer_donation_links.count).to eq 10
        end

        it "has a link to create a new donation" do
          org_dashboard_page.visit

          expect(org_dashboard_page).to have_manufacturers_section
        end

        # it "doesn't count inactive items" do
        #   item = create(:manufacturer_donation, :with_items, item_quantity: 100, storage_location: storage_location).items.first
        #
        #   visit subject
        #   within "#manufacturers" do
        #     expect(page).to have_content("100")
        #   end
        #
        #   item.update!(active: false)
        #   visit subject
        #   within "#donations" do
        #     expect(page).to have_no_content("100")
        #   end
        # end

        context "when constrained to date range" do
          before do
            @organization.donations.destroy_all
            storage_location = create(:storage_location, :with_items, item_quantity: 0, organization: @organization)
            manufacturer1 = create(:manufacturer, name: "ABC Corp", organization: @organization)
            manufacturer2 = create(:manufacturer, name: "BCD Corp", organization: @organization)
            manufacturer3 = create(:manufacturer, name: "CDE Corp", organization: @organization)
            # manufacturer4 = create(:manufacturer, name: "DEF Corp", organization: @organization)

            @this_years_donations = {
              today: create(:manufacturer_donation, :with_items, manufacturer: manufacturer1, issued_at: date_to_view, item_quantity: 100, storage_location: storage_location, organization: @organization),
              yesterday: create(:manufacturer_donation, :with_items, manufacturer: manufacturer2, issued_at: date_to_view.yesterday, item_quantity: 101, storage_location: storage_location, organization: @organization),
              earlier_this_week: create(:manufacturer_donation, :with_items, manufacturer: manufacturer3, issued_at: date_to_view.beginning_of_week, item_quantity: 102, storage_location: storage_location, organization: @organization)
              # See https://github.com/rubyforgood/human-essentials/issues/2676#issuecomment-1008166066
              # beginning_of_year: create(:manufacturer_donation, :with_items, manufacturer: manufacturer4, issued_at: beginning_of_year, item_quantity: 103, storage_location: storage_location, organization: @organization)
            }
            @last_years_donations = create_list(:manufacturer_donation, 2, :with_items, manufacturer: manufacturer1, issued_at: last_year_date, item_quantity: 104, storage_location: storage_location, organization: @organization)
            org_dashboard_page.visit
          end

          describe "This Year" do
            before do
              org_dashboard_page.filter_to_date_range "This Year"
            end

            let(:total_inventory) { @this_years_donations.values.map(&:total_quantity).sum }
            let(:manufacturers) { @this_years_donations.values.map(&:manufacturer).map(&:name) }

            it "has a widget displaying the year-to-date Donation totals, only using donations from this year" do
              expect(org_dashboard_page.manufacturers_total_donations).to eq total_inventory
              expect(org_dashboard_page.num_manufacturers_donated).to eq manufacturers.size
            end

            it "displays the list of top manufacturers" do
              recent_manufacturer_donation_links = org_dashboard_page.recent_manufacturer_donation_links

              manufacturers.each do |manufacturer|
                expect(recent_manufacturer_donation_links)
                  .to include(match /#{manufacturer} \(\d{3}\)/i)
                  .exactly(:once)
              end
            end
          end

          describe "Today" do
            before do
              org_dashboard_page.filter_to_date_range "Today"
            end

            let(:total_inventory) { @this_years_donations[:today].total_quantity }
            let(:manufacturer) { @this_years_donations[:today].manufacturer.name }

            it "has a widget displaying today's Donation totals, only using donations from today" do
              expect(org_dashboard_page.manufacturers_total_donations).to eq total_inventory
            end

            it "displays the list of top manufacturers" do
              expect(org_dashboard_page.recent_manufacturer_donation_links)
                .to include(match /#{manufacturer} \(\d{3}\)/i)
                .exactly(:once)
            end
          end

          describe "Yesterday" do
            before do
              org_dashboard_page.filter_to_date_range "Yesterday"
            end

            let(:total_inventory) { @this_years_donations[:yesterday].total_quantity }
            let(:manufacturer) { @this_years_donations[:yesterday].manufacturer.name }

            it "has a widget displaying the Donation totals from yesterday, only using donations from yesterday" do
              expect(org_dashboard_page.manufacturers_total_donations).to eq total_inventory
            end

            it "displays the list of top manufacturers" do
              expect(org_dashboard_page.recent_manufacturer_donation_links)
                .to include(match /#{manufacturer} \(\d{3}\)/i)
                .exactly(:once)
            end
          end

          describe "This Week" do
            before do
              org_dashboard_page.filter_to_date_range "Last 7 Days"
            end

            let(:total_inventory) { [@this_years_donations[:today], @this_years_donations[:yesterday], @this_years_donations[:earlier_this_week]].map(&:total_quantity).sum }
            let(:manufacturers) { [@this_years_donations[:today], @this_years_donations[:yesterday], @this_years_donations[:earlier_this_week]].map(&:manufacturer).map(&:name) }

            it "has a widget displaying the Donation totals from this week, only using donations from this week" do
              expect(org_dashboard_page.manufacturers_total_donations).to eq total_inventory
            end

            it "displays the list of top manufacturers" do
              recent_manufacturer_donation_links = org_dashboard_page.recent_manufacturer_donation_links

              manufacturers.each do |manufacturer|
                expect(recent_manufacturer_donation_links)
                  .to include(match /#{manufacturer} \(\d{3}\)/i)
                  .exactly(:once)
              end
            end
          end

          describe "This Month" do
            before do
              org_dashboard_page.filter_to_date_range "This Month"
            end

            let(:total_inventory) { @this_years_donations[:today].total_quantity + @this_years_donations[:yesterday].total_quantity + @this_years_donations[:earlier_this_week].total_quantity }
            let(:manufacturer) { @this_years_donations[:today].manufacturer.name }

            it "has a widget displaying the Donation totals from this month, only using donations from this month" do
              expect(org_dashboard_page.manufacturers_total_donations).to eq total_inventory
            end

            it "displays the list of top manufacturers" do
              expect(org_dashboard_page.recent_manufacturer_donation_links)
                .to include(match /#{manufacturer} \(\d{3}\)/i)
                .exactly(:once)
            end
          end

          describe "All Time" do
            before do
              org_dashboard_page.filter_to_date_range "All Time"
            end

            let(:total_inventory) { @this_years_donations.values.map(&:total_quantity).sum + @last_years_donations.map(&:total_quantity).sum }
            let(:manufacturers) { [@this_years_donations.values + @last_years_donations].flatten.map(&:manufacturer).map(&:name) }

            it "has a widget displaying the Donation totals from last year, only using donations from last year" do
              expect(org_dashboard_page.manufacturers_total_donations).to eq total_inventory
            end

            it "displays the list of top manufacturers" do
              recent_manufacturer_donation_links = org_dashboard_page.recent_manufacturer_donation_links

              manufacturers.each do |manufacturer|
                expect(recent_manufacturer_donation_links)
                  .to include(match /#{manufacturer} \(\d{3}\)/i)
                  .exactly(:once)
              end
            end
          end
        end
      end

      describe "Distributions" do
        around do |example|
          travel_to(date_to_view)
          example.run
          travel_back
        end

        before do
          @organization.distributions.destroy_all
          storage_location = create(:storage_location, :with_items, item_quantity: 500, organization: @organization)

          partner1 = create(:partner, name: "Partner ABC", organization: @organization)
          partner2 = create(:partner, name: "Partner BCD", organization: @organization)
          partner3 = create(:partner, name: "Partner CDE", organization: @organization)
          partner4 = create(:partner, name: "Partner DEF", organization: @organization)

          @this_years_distributions = {
            today: create(:distribution, :with_items, partner: partner1, issued_at: date_to_view, item_quantity: 10, storage_location: storage_location, organization: @organization),
            yesterday: create(:distribution, :with_items, partner: partner2, issued_at: date_to_view.yesterday, item_quantity: 11, storage_location: storage_location, organization: @organization),
            earlier_this_week: create(:distribution, :with_items, partner: partner3, issued_at: date_to_view.beginning_of_week, item_quantity: 12, storage_location: storage_location, organization: @organization),
            beginning_of_year: create(:distribution, :with_items, partner: partner4, issued_at: beginning_of_year, item_quantity: 13, storage_location: storage_location, organization: @organization)
          }
          @last_years_distributions = create_list(:distribution, 2, :with_items, partner: partner1, issued_at: last_year_date, item_quantity: 14, storage_location: storage_location, organization: @organization)
          org_dashboard_page.visit
        end

        it "has a link to create a new distribution" do
          org_new_distribution_page = OrganizationNewDistributionPage.new org_short_name: org_short_name

          expect(org_dashboard_page).to have_distributions_section

          expect { org_dashboard_page.create_new_distribution }
            .to change { page.current_path }
            .to org_new_distribution_page.path
        end

        # it "doesn't count inactive items" do
        #   item = create(:inventory_item, quantity: 100, storage_location: storage_location).item
        #   create(:distribution, :with_items, item: item, item_quantity: 100, storage_location: storage_location)
        #
        #   visit subject
        #   within "#distributions" do
        #     expect(page).to have_content("100")
        #   end
        #
        #   item.update!(active: false)
        #   visit subject
        #   within "#distributions" do
        #     expect(page).to have_no_content("100")
        #   end
        # end

        context "When Date Filtering >" do
          before do
          end

          context "with year-to-date selected" do
            before do
              org_dashboard_page.filter_to_date_range "This Year"
            end

            let(:total_inventory) { @this_years_distributions.values.map(&:line_items).flatten.map(&:quantity).sum }
            let(:partners) { @this_years_distributions.values.map(&:partner).map(&:name) }

            it "has a widget displaying the year-to-date distribution totals, only using distributions from this year" do
              expect(org_dashboard_page.total_distributed).to eq total_inventory
            end

            it "displays some recent distributions" do
              expected_partner_names_pattern = partners.join('|')

              expect(org_dashboard_page.recent_distribution_links)
                .to include(match /1\d items.*(#{expected_partner_names_pattern})/i)
                .exactly(3).times
            end
          end

          context "with today selected" do
            before do
              org_dashboard_page.filter_to_date_range "Today"
            end

            let(:total_inventory) { @this_years_distributions[:today].line_items.total }
            let(:partner) { @this_years_distributions[:today].partner.name }

            it "has a widget displaying today's distributions totals, only using distributions from today" do
              expect(org_dashboard_page.total_distributed).to eq total_inventory
            end

            it "displays some recent distributions" do
              expect(org_dashboard_page.recent_distribution_links)
                .to include(match /1\d items.*(#{partner})/i)
                .exactly(:once)
            end
          end

          context "with yesterday selected" do
            before do
              org_dashboard_page.filter_to_date_range "Yesterday"
            end

            let(:total_inventory) { @this_years_distributions[:yesterday].line_items.total }
            let(:partner) { @this_years_distributions[:yesterday].partner.name }

            it "has a widget displaying the distributions totals from yesterday, only using distributions from yesterday" do
              expect(org_dashboard_page.total_distributed).to eq total_inventory
            end

            it "displays some recent distributions" do
              expect(org_dashboard_page.recent_distribution_links)
                .to include(match /1\d items.*(#{partner})/i)
                .exactly(:once)
            end
          end

          context "with this week selected" do
            before do
              org_dashboard_page.filter_to_date_range "Last 7 Days"
            end

            let(:total_inventory) { [@this_years_distributions[:today], @this_years_distributions[:yesterday], @this_years_distributions[:earlier_this_week]].map(&:line_items).flatten.map(&:quantity).sum }
            let(:partners) { [@this_years_distributions[:today], @this_years_distributions[:yesterday], @this_years_distributions[:earlier_this_week]].map(&:partner).map(&:name) }

            it "has a widget displaying the distributions totals from this week, only using distributions from this week" do
              expect(org_dashboard_page.total_distributed).to eq total_inventory
            end

            it "displays some recent distributions" do
              recent_distribution_links = org_dashboard_page.recent_distribution_links

              partners.each do |partner|
                expect(recent_distribution_links)
                  .to include(match /1\d items.*(#{partner})/i)
                  .exactly(:once)
              end
            end
          end

          context "with this month selected" do
            before do
              org_dashboard_page.filter_to_date_range "This Month"
            end

            let(:total_inventory) { %i[today yesterday earlier_this_week].map { |date| @this_years_distributions[date].line_items }.flatten.map(&:quantity).sum }
            let(:partner) { @this_years_distributions[:today].partner.name }

            it "has a widget displaying the distributions totals from this month, only using distributions from this month" do
              expect(org_dashboard_page.total_distributed).to eq total_inventory
            end

            it "displays some recent distributions" do
              expect(org_dashboard_page.recent_distribution_links)
                .to include(match /1\d items.*(#{partner})/i)
                .exactly(:once)
            end
          end

          context "with All Time selected" do
            before do
              org_dashboard_page.filter_to_date_range "All Time"
            end

            let(:total_inventory) { @this_years_distributions.values.map(&:line_items).flatten.map(&:quantity).sum + @last_years_distributions.map(&:line_items).flatten.map(&:quantity).sum }
            let(:partners) { [@this_years_distributions.values + @last_years_distributions].flatten.map(&:partner).map(&:name) }

            it "has a widget displaying the distributions totals from last year, only using distributions from last year" do
              expect(org_dashboard_page.total_distributed).to eq total_inventory
            end

            it "displays some recent distributions from that time" do
              expected_partner_names_pattern = partners.join('|')

              expect(org_dashboard_page.recent_distribution_links)
                .to include(match /1\d items.*(#{expected_partner_names_pattern})/i)
                .exactly(3).times
            end
          end
        end
      end
    end
  end
end
