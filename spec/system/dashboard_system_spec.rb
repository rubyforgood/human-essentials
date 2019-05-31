RSpec.describe "Dashboard", type: :system, js: true do
  context "With a new Diaper bank" do
    before :each do
      @new_organization = create(:organization)
      @user = create(:user, organization: @new_organization)
      @url_prefix = "/#{@new_organization.short_name}"
    end
    attr_reader :new_organization, :user, :url_prefix

    subject { url_prefix + "/dashboard" }

    before do
      sign_in(user)
    end

    it "displays the getting started guide until the steps are completed" do
      # When dashboard loads, ensure that we are on step 1 (Partner Agencies)
      visit subject
      expect(page).to have_selector("#getting-started-guide", count: 1)
      expect(page).to have_selector("#org-stats-call-to-action-partners", count: 1)
      expect(page).to have_selector("#org-stats-call-to-action-storage-locations", count: 0)
      expect(page).to have_selector("#org-stats-call-to-action-donation-sites", count: 0)
      expect(page).to have_selector("#org-stats-call-to-action-inventory", count: 0)

      # After we create a partner, ensure that we are on step 2 (Storage Locations)
      @partner = create(:partner, organization: new_organization)
      visit subject
      expect(page).to have_selector("#getting-started-guide", count: 1)
      expect(page).to have_selector("#org-stats-call-to-action-partners", count: 0)
      expect(page).to have_selector("#org-stats-call-to-action-storage-locations", count: 1)
      expect(page).to have_selector("#org-stats-call-to-action-donation-sites", count: 0)
      expect(page).to have_selector("#org-stats-call-to-action-inventory", count: 0)

      # After we create a storage location, ensure that we are on step 3 (Donation Site)
      create(:storage_location, organization: new_organization)
      visit subject
      expect(page).to have_selector("#getting-started-guide", count: 1)
      expect(page).to have_selector("#org-stats-call-to-action-partners", count: 0)
      expect(page).to have_selector("#org-stats-call-to-action-storage-locations", count: 0)
      expect(page).to have_selector("#org-stats-call-to-action-donation-sites", count: 1)
      expect(page).to have_selector("#org-stats-call-to-action-inventory", count: 0)

      # After we create a donation site, ensure that we are on step 4 (Inventory)
      create(:donation_site, organization: new_organization)
      visit subject
      expect(page).to have_selector("#getting-started-guide", count: 1)
      expect(page).to have_selector("#org-stats-call-to-action-partners", count: 0)
      expect(page).to have_selector("#org-stats-call-to-action-storage-locations", count: 0)
      expect(page).to have_selector("#org-stats-call-to-action-donation-sites", count: 0)
      expect(page).to have_selector("#org-stats-call-to-action-inventory", count: 1)

      # After we add inventory to a storage location, ensure that the getting starting guide is gone
      create(:storage_location, :with_items, item_quantity: 125, organization: new_organization)
      visit subject
      expect(page).to have_selector("#getting-started-guide", count: 0)
    end
  end

  context "With an existing Diaper bank" do
    before do
      sign_in(@user)
    end

    let!(:url_prefix) { "/#{@organization.short_name}" }
    subject { url_prefix + "/dashboard" }

    describe "Signage" do
      it "shows their organization name unless they have a logo set" do
        visit subject
        # extract just the filename
        header_logo = extract_image(:xpath, "//img[@id='logo']")
        expect(header_logo).to be_include("diaper-base-logo")

        organization_logo = extract_image(:xpath, "//div/img")
        expect(organization_logo).to eq("logo.jpg")

        @organization.logo.purge
        @organization.save
        visit subject

        expect(page).not_to have_xpath("//div/img")
        expect(page.find(:xpath, "//div[@class='logo']")).to have_content(@organization.name)
      end
    end

    describe "Date Ranges" do

      it "should scope down what the user sees in the dashboard using the date-range drop down" do
        Timecop.freeze(Time.utc(2018, 6, 15, 12, 0, 0)) do
          item = create(:item, organization: @organization)
          sl = create(:storage_location, :with_items, item: item, item_quantity: 125, organization: @organization)
          create(:donation, :with_items, item: item, item_quantity: 10, storage_location: sl, issued_at: 1.month.ago)
          create(:donation, :with_items, item: item, item_quantity: 200, storage_location: sl, issued_at: Time.zone.today)
          create(:distribution, :with_items, item: item, item_quantity: 5, storage_location: sl, issued_at: 1.month.ago,)
          create(:distribution, :with_items, item: item, item_quantity: 100, storage_location: sl, issued_at: Time.zone.today,)

          m_a = create(:manufacturer)
          m_b = create(:manufacturer)
          create(:donation, :with_items, item: item, item_quantity: 25, source: Donation::SOURCES[:manufacturer], manufacturer: m_a, issued_at: 1.month.ago)
          create(:donation, :with_items, item: item, item_quantity: 75, source: Donation::SOURCES[:manufacturer], manufacturer: m_b, issued_at: Time.zone.today)

          # Verify the initial totals are correct
          visit url_prefix + "/dashboard"
          expect(page).to have_content("310 items received year to date")
          expect(page).to have_content("105 items distributed year to date")
          expect(page).to have_content("0 Diaper Drives")
          expect(page).to have_content("100 items donated year to date by 2 Manufacturers")

          # Scope it down to just today, should omit the first donation
          # select "Yesterday", from: "dashboard_filter_interval" # LET'S PRETEND BECAUSE OF REASONS!
          visit url_prefix + "/dashboard?dashboard_filter[interval]=last_month"
          expect(page).to have_content("35 items received last month")
          expect(page).to have_content("5 items distributed last month")
          expect(page).to have_content("25 items donated last month by 1 Manufacturer")
        end
      end
    end

    describe "Inventory Totals" do
#      let(:donation) { create(:donation, :with_items, organization: @organization) }
#      let(:purchase) { create(:purchase, :with_items, organization: @organization) }
#      let(:distribution) { create(:distribution, :with_items, organization: @organization) }

      before do
#        create(:partner)
#        create(:item, organization: @organization)
#        create(:storage_location, organization: @organization)
#        create(:donation_site, organization: @organization)
#        create(:diaper_drive_participant, organization: @organization)
#        create(:manufacturer, organization: @organization)
#        @organization.reload
      end

      describe "Donations" do
        around do |example|
          Timecop.travel(Date.parse("June 1 2018")) do
            example.run
          end
        end

        before do
          @organization.donations.destroy_all
          storage_location = create(:storage_location, :with_items, item_quantity: 0, organization: @organization)
          @this_years_donations = {
            today: create(:donation, :with_items, issued_at: Time.zone.now, item_quantity: 100, storage_location: storage_location, organization: @organization),
            yesterday: create(:diaper_drive_donation, :with_items, issued_at: Time.zone.yesterday, item_quantity: 101, storage_location: storage_location, organization: @organization),
            earlier_this_week: create(:donation_site_donation, :with_items, issued_at: Time.zone.now.beginning_of_week, item_quantity: 102, storage_location: storage_location, organization: @organization),
            beginning_of_year: create(:manufacturer_donation, :with_items, issued_at: Time.zone.parse("January 1, 2018 12:01am"), item_quantity: 103, storage_location: storage_location, organization: @organization)
          }
          @last_years_donations = create_list(:donation, 2, :with_items, issued_at: Time.zone.parse("June 1, 2017"), item_quantity: 104, storage_location: storage_location, organization: @organization)
          visit subject
        end

        it "has a link to create a new donation" do
          expect(page).to have_css("#donations")          
          within "#donations" do
            expect(page).to have_xpath("//a[@href='#{new_donation_path(organization_id: @organization.to_param)}']", visible: false)
          end
        end

        context "with year-to-date selected" do
          before do
            page.select "Year to date", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @this_years_donations.values.map(&:total_quantity).sum }

          it "has a widget displaying the year-to-date Donation totals, only using donations from this year" do
            within "#donations" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent donations" do
            within "#donations" do
              expect(page).to have_css("a", text: /10\d items/i, count: 3)
            end
          end
        end

        context "with today selected" do
          before do
            page.select "Today", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @this_years_donations[:today].total_quantity }

          it "has a widget displaying today's Donation totals, only using donations from today" do
            within "#donations" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent donations" do
            within "#donations" do
              expect(page).to have_css("a", text: /#{total_inventory} items/i, count: 1)
            end
          end
        end

        context "with yesterday selected" do
          before do
            page.select "Yesterday", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @this_years_donations[:yesterday].total_quantity }

          it "has a widget displaying the Donation totals from yesterday, only using donations from yesterday" do
            within "#donations" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent donations" do
            within "#donations" do
              expect(page).to have_css("a", text: /#{total_inventory} items/i, count: 1)
            end
          end
        end

        context "with this week selected" do
          before do
            page.select "This Week", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { [ @this_years_donations[:today], @this_years_donations[:yesterday], @this_years_donations[:earlier_this_week] ].map(&:total_quantity).sum }

          it "has a widget displaying the Donation totals from this week, only using donations from this week" do
            within "#donations" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent donations" do
            within "#donations" do
              expect(page).to have_css("a", text: /10\d items/i, count: 3)
            end
          end
        end

        context "with this month selected" do
          before do
            page.select "This Month", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @this_years_donations[:today].total_quantity }

          it "has a widget displaying the Donation totals from this month, only using donations from this month" do
            within "#donations" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent donations" do
            within "#donations" do
              expect(page).to have_css("a", text: /#{total_inventory} items/i, count: 1)
            end
          end
        end

        context "with last month selected" do
          before do
            page.select "Last Month", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { [ @this_years_donations[:yesterday], @this_years_donations[:earlier_this_week] ].map(&:total_quantity).sum }

          it "has a widget displaying the Donation totals from last month, only using donations from last month" do
            within "#donations" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent donations" do
            within "#donations" do
              expect(page).to have_css("a", text: /10\d items/i, count: 2)
            end
          end
        end

        context "with last year selected" do
          before do
            page.select "Last Year", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @last_years_donations.map(&:total_quantity).sum }

          it "has a widget displaying the Donation totals from last year, only using donations from last year" do
            within "#donations" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent donations from that time" do
            within "#donations" do
              expect(page).to have_css("a", text: /10\d items/i, count: 2)
            end
          end
        end

        context "with all time selected" do
          before do
            page.select "All time", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @this_years_donations.values.map(&:total_quantity).sum + @last_years_donations.map(&:total_quantity).sum }

          it "has a widget displaying the Donation totals from last year, only using donations from last year" do
            within "#donations" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent donations from that time" do
            within "#donations" do
              expect(page).to have_css("a", text: /10\d items/i, count: 3)
            end
          end
        end                
      end

      describe "Purchases" do
        around do |example|
          Timecop.travel(Date.parse("June 1 2018")) do
            example.run
          end
        end

        before do
          @organization.purchases.destroy_all
          storage_location = create(:storage_location, :with_items, item_quantity: 0, organization: @organization)
          @this_years_purchases = {
            today: create(:purchase, :with_items, issued_at: Time.zone.now, item_quantity: 100, storage_location: storage_location, organization: @organization),
            yesterday: create(:purchase, :with_items, issued_at: Time.zone.yesterday, item_quantity: 101, storage_location: storage_location, organization: @organization),
            earlier_this_week: create(:purchase, :with_items, issued_at: Time.zone.now.beginning_of_week, item_quantity: 102, storage_location: storage_location, organization: @organization),
            beginning_of_year: create(:purchase, :with_items, issued_at: Time.zone.parse("January 1, 2018 12:01am"), item_quantity: 103, storage_location: storage_location, organization: @organization)
          }
          @last_years_purchases = create_list(:purchase, 2, :with_items, issued_at: Time.zone.parse("June 1, 2017"), item_quantity: 104, storage_location: storage_location, organization: @organization)
          visit subject
        end

        it "has a link to create a new purchase" do
          expect(page).to have_css("#purchases")          
          within "#purchases" do
            expect(page).to have_xpath("//a[@href='#{new_purchase_path(organization_id: @organization.to_param)}']", visible: false)
          end
        end

        context "with year-to-date selected" do
          before do
            page.select "Year to date", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @this_years_purchases.values.map(&:total_quantity).sum }

          it "has a widget displaying the year-to-date Purchase totals, only using purchases from this year" do
            within "#purchases" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent purchases" do
            within "#purchases" do
              expect(page).to have_css("a", text: /10\d items/i, count: 3)
            end
          end
        end

        context "with today selected" do
          before do
            page.select "Today", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @this_years_purchases[:today].total_quantity }

          it "has a widget displaying today's Purchase totals, only using purchases from today" do
            within "#purchases" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent purchases" do
            within "#purchases" do
              expect(page).to have_css("a", text: /#{total_inventory} items/i, count: 1)
            end
          end
        end

        context "with yesterday selected" do
          before do
            page.select "Yesterday", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @this_years_purchases[:yesterday].total_quantity }

          it "has a widget displaying the Purchase totals from yesterday, only using purchases from yesterday" do
            within "#purchases" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent purchases" do
            within "#purchases" do
              expect(page).to have_css("a", text: /#{total_inventory} items/i, count: 1)
            end
          end
        end

        context "with this week selected" do
          before do
            page.select "This Week", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { [ @this_years_purchases[:today], @this_years_purchases[:yesterday], @this_years_purchases[:earlier_this_week] ].map(&:total_quantity).sum }

          it "has a widget displaying the Purchase totals from this week, only using purchases from this week" do
            within "#purchases" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent purchases" do
            within "#purchases" do
              expect(page).to have_css("a", text: /10\d items/i, count: 3)
            end
          end
        end

        context "with this month selected" do
          before do
            page.select "This Month", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @this_years_purchases[:today].total_quantity }

          it "has a widget displaying the Purchase totals from this month, only using purchases from this month" do
            within "#purchases" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent purchases" do
            within "#purchases" do
              expect(page).to have_css("a", text: /#{total_inventory} items/i, count: 1)
            end
          end
        end

        context "with last month selected" do
          before do
            page.select "Last Month", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { [ @this_years_purchases[:yesterday], @this_years_purchases[:earlier_this_week] ].map(&:total_quantity).sum }

          it "has a widget displaying the Purchase totals from last month, only using purchases from last month" do
            within "#purchases" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent purchases" do
            within "#purchases" do
              expect(page).to have_css("a", text: /10\d items/i, count: 2)
            end
          end
        end

        context "with last year selected" do
          before do
            page.select "Last Year", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @last_years_purchases.map(&:total_quantity).sum }

          it "has a widget displaying the Purchase totals from last year, only using purchases from last year" do
            within "#purchases" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent purchases from that time" do
            within "#purchases" do
              expect(page).to have_css("a", text: /10\d items/i, count: 2)
            end
          end
        end

        context "with all time selected" do
          before do
            page.select "All time", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @this_years_purchases.values.map(&:total_quantity).sum + @last_years_purchases.map(&:total_quantity).sum }

          it "has a widget displaying the Purchase totals from last year, only using purchases from last year" do
            within "#purchases" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent purchases from that time" do
            within "#purchases" do
              expect(page).to have_css("a", text: /10\d items/i, count: 3)
            end
          end
        end                
      end

      describe "Diaper Drives" do
        around do |example|
          Timecop.travel(Date.parse("June 1 2018")) do
            example.run
          end
        end

        before do
          @organization.donations.destroy_all
          storage_location = create(:storage_location, :with_items, item_quantity: 0, organization: @organization)
          diaper_drive_1 = create(:diaper_drive_participant, business_name: "First Diaper Drive", organization: @organization)
          diaper_drive_2 = create(:diaper_drive_participant, business_name: "Second Diaper Drive", organization: @organization)

          @this_years_donations = {
            today: create(:diaper_drive_donation, :with_items, diaper_drive_participant: diaper_drive_1, issued_at: Time.zone.now, item_quantity: 100, storage_location: storage_location, organization: @organization),
            yesterday: create(:diaper_drive_donation, :with_items, diaper_drive_participant: diaper_drive_2, issued_at: Time.zone.yesterday, item_quantity: 101, storage_location: storage_location, organization: @organization),
            earlier_this_week: create(:diaper_drive_donation, :with_items, diaper_drive_participant: diaper_drive_1, issued_at: Time.zone.now.beginning_of_week, item_quantity: 102, storage_location: storage_location, organization: @organization),
            beginning_of_year: create(:diaper_drive_donation, :with_items, diaper_drive_participant: diaper_drive_2, issued_at: Time.zone.parse("January 1, 2018 12:01am"), item_quantity: 103, storage_location: storage_location, organization: @organization)
          }

          @last_years_donations = create_list(:diaper_drive_donation, 2, :with_items, diaper_drive_participant: diaper_drive_1, issued_at: Time.zone.parse("June 1, 2017"), item_quantity: 104, storage_location: storage_location, organization: @organization)
          visit subject
        end

        it "has a widget for diaper drive summary data" do
          expect(page).to have_css("#diaper_drives")          
        end

        context "with year-to-date selected" do
          before do
            page.select "Year to date", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @this_years_donations.values.map(&:total_quantity).sum }

          it "has a widget displaying the year-to-date Diaper drive totals, only using donations from this year" do
            within "#diaper_drives" do
              expect(page).to have_content(/2 diaper drives/i)
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent donations" do
            within "#diaper_drives" do
              expect(page).to have_css("a", text: /10\d from (first|second) diaper drive/i, count: 3)
            end
          end
        end

        context "with today selected" do
          before do
            page.select "Today", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @this_years_donations[:today].total_quantity }

          it "has a widget displaying today's Diaper drive totals, only using donations from today" do
            within "#diaper_drives" do
              expect(page).to have_content(/1 diaper drive/i)
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent donations" do
            within "#diaper_drives" do
              expect(page).to have_css("a", text: /#{total_inventory} from first diaper drive/i, count: 1)
            end
          end
        end

        context "with yesterday selected" do
          before do
            page.select "Yesterday", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @this_years_donations[:yesterday].total_quantity }

          it "has a widget displaying the Diaper drive totals from yesterday, only using donations from yesterday" do
            within "#diaper_drives" do
              expect(page).to have_content(/1 diaper drive/i)
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent donations" do
            within "#diaper_drives" do
              expect(page).to have_css("a", text: /#{total_inventory} from second diaper drive/i, count: 1)
            end
          end
        end

        context "with this week selected" do
          before do
            page.select "This Week", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { [ @this_years_donations[:today], @this_years_donations[:yesterday], @this_years_donations[:earlier_this_week] ].map(&:total_quantity).sum }

          it "has a widget displaying the Diaper drive totals from this week, only using donations from this week" do
            within "#diaper_drives" do
              expect(page).to have_content(/2 diaper drives/i)
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent donations" do
            within "#diaper_drives" do
              expect(page).to have_css("a", text: /10\d from (first|second) diaper drive/i, count: 3)
            end
          end
        end

        context "with this month selected" do
          before do
            page.select "This Month", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @this_years_donations[:today].total_quantity }

          it "has a widget displaying the Diaper drive totals from this month, only using donations from this month" do
            within "#diaper_drives" do
              expect(page).to have_content(/1 diaper drive/i)
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent donations" do
            within "#diaper_drives" do
              expect(page).to have_css("a", text: /#{total_inventory} from first diaper drive/i, count: 1)
            end
          end
        end

        context "with last month selected" do
          before do
            page.select "Last Month", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { [ @this_years_donations[:yesterday], @this_years_donations[:earlier_this_week] ].map(&:total_quantity).sum }

          it "has a widget displaying the Diaper drive totals from last month, only using donations from last month" do
            within "#diaper_drives" do
              expect(page).to have_content(/2 diaper drives/i)
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent donations" do
            within "#diaper_drives" do
              expect(page).to have_css("a", text: /10\d from (first|second) diaper drive/i, count: 2)
            end
          end
        end

        context "with last year selected" do
          before do
            page.select "Last Year", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @last_years_donations.map(&:total_quantity).sum }

          it "has a widget displaying the Diaper drive totals from last year, only using donations from last year" do
            within "#diaper_drives" do
              expect(page).to have_content(total_inventory)
              expect(page).to have_content(/1 diaper drive/i)
            end
          end

          it "displays some recent donations from that time" do
            within "#diaper_drives" do
              expect(page).to have_css("a", text: /10\d from first diaper drive/i, count: 2)
            end
          end
        end

        context "with all time selected" do
          before do
            page.select "All time", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @this_years_donations.values.map(&:total_quantity).sum + @last_years_donations.map(&:total_quantity).sum }

          it "has a widget displaying the Diaper drive totals from last year, only using donations from last year" do
            within "#diaper_drives" do
              expect(page).to have_content(total_inventory)
              expect(page).to have_content(/2 diaper drives/i)
            end
          end

          it "displays some recent donations from that time" do
            within "#diaper_drives" do
              expect(page).to have_css("a", text: /10\d from (first|second) diaper drive/i, count: 3)
            end
          end
        end                
      end

      describe "Manufacturer Donations" do
        around do |example|
          Timecop.travel(Date.parse("June 1 2018")) do
            example.run
          end
        end

        before do
          @organization.donations.destroy_all
          storage_location = create(:storage_location, :with_items, item_quantity: 0, organization: @organization)
          manufacturer_1 = create(:manufacturer, name: "ABC Corp", organization: @organization)
          manufacturer_2 = create(:manufacturer, name: "BCD Corp", organization: @organization)
          manufacturer_3 = create(:manufacturer, name: "CDE Corp", organization: @organization)
          manufacturer_4 = create(:manufacturer, name: "DEF Corp", organization: @organization)

          @this_years_donations = {
            today: create(:manufacturer_donation, :with_items, manufacturer: manufacturer_1, issued_at: Time.zone.now, item_quantity: 100, storage_location: storage_location, organization: @organization),
            yesterday: create(:manufacturer_donation, :with_items, manufacturer: manufacturer_2, issued_at: Time.zone.yesterday, item_quantity: 101, storage_location: storage_location, organization: @organization),
            earlier_this_week: create(:manufacturer_donation, :with_items, manufacturer: manufacturer_3, issued_at: Time.zone.now.beginning_of_week, item_quantity: 102, storage_location: storage_location, organization: @organization),
            beginning_of_year: create(:manufacturer_donation, :with_items, manufacturer: manufacturer_4, issued_at: Time.zone.parse("January 1, 2018 12:01am"), item_quantity: 103, storage_location: storage_location, organization: @organization)
          }
          @last_years_donations = create_list(:manufacturer_donation, 2, :with_items, manufacturer: manufacturer_1, issued_at: Time.zone.parse("June 1, 2017"), item_quantity: 104, storage_location: storage_location, organization: @organization)
          visit subject
        end

        it "has a link to create a new donation" do
          expect(page).to have_css("#manufacturers")          
        end

        context "with year-to-date selected" do
          before do
            page.select "Year to date", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @this_years_donations.values.map(&:total_quantity).sum }
          let(:manufacturers) { @this_years_donations.values.map(&:manufacturer).map(&:name) }

          it "has a widget displaying the year-to-date Donation totals, only using donations from this year" do
            within "#manufacturers" do
              expect(page).to have_content(total_inventory)
              expect(page).to have_content(/#{manufacturers.size} manufacturer/i)
            end
          end

          it "displays the list of top manufacturers" do
            within "#manufacturers" do
              manufacturers.each do |manufacturer|
                expect(page).to have_css("a", text: /#{manufacturer} \(\d{3}\)/i, count: 1)
              end
            end
          end
        end

        context "with today selected" do
          before do
            page.select "Today", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @this_years_donations[:today].total_quantity }
          let(:manufacturer) { @this_years_donations[:today].manufacturer.name }

          it "has a widget displaying today's Donation totals, only using donations from today" do
            within "#manufacturers" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays the list of top manufacturers" do
            within "#manufacturers" do
              expect(page).to have_css("a", text: /#{manufacturer} \(\d{3}\)/i, count: 1)
            end
          end
        end

        context "with yesterday selected" do
          before do
            page.select "Yesterday", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @this_years_donations[:yesterday].total_quantity }
          let(:manufacturer) { @this_years_donations[:yesterday].manufacturer.name }

          it "has a widget displaying the Donation totals from yesterday, only using donations from yesterday" do
            within "#manufacturers" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays the list of top manufacturers" do
            within "#manufacturers" do
              expect(page).to have_css("a", text: /#{manufacturer} \(\d{3}\)/i, count: 1)
            end
          end
        end

        context "with this week selected" do
          before do
            page.select "This Week", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { [ @this_years_donations[:today], @this_years_donations[:yesterday], @this_years_donations[:earlier_this_week] ].map(&:total_quantity).sum }
          let(:manufacturers) { [ @this_years_donations[:today], @this_years_donations[:yesterday], @this_years_donations[:earlier_this_week] ].map(&:manufacturer).map(&:name) }

          it "has a widget displaying the Donation totals from this week, only using donations from this week" do
            within "#manufacturers" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays the list of top manufacturers" do
            within "#manufacturers" do
              manufacturers.each do |manufacturer|
                expect(page).to have_css("a", text: /#{manufacturer} \(\d{3}\)/i, count: 1)
              end
            end
          end
        end

        context "with this month selected" do
          before do
            page.select "This Month", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @this_years_donations[:today].total_quantity }
          let(:manufacturer) { @this_years_donations[:today].manufacturer.name }

          it "has a widget displaying the Donation totals from this month, only using donations from this month" do
            within "#manufacturers" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays the list of top manufacturers" do
            within "#manufacturers" do
              expect(page).to have_css("a", text: /#{manufacturer} \(\d{3}\)/i, count: 1)
            end
          end
        end

        context "with last month selected" do
          before do
            page.select "Last Month", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { [ @this_years_donations[:yesterday], @this_years_donations[:earlier_this_week] ].map(&:total_quantity).sum }
          let(:manufacturers) { [ @this_years_donations[:yesterday], @this_years_donations[:earlier_this_week] ].map(&:manufacturer).map(&:name) }

          it "has a widget displaying the Donation totals from last month, only using donations from last month" do
            within "#manufacturers" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays the list of top manufacturers" do
            within "#manufacturers" do
              manufacturers.each do |manufacturer|
                expect(page).to have_css("a", text: /#{manufacturer} \(\d{3}\)/i, count: 1)
              end
            end
          end
        end

        context "with last year selected" do
          before do
            page.select "Last Year", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @last_years_donations.map(&:total_quantity).sum }
          let(:manufacturers) { @last_years_donations.map(&:manufacturer).map(&:name) }

          it "has a widget displaying the Donation totals from last year, only using donations from last year" do
            within "#manufacturers" do
              expect(page).to have_content(total_inventory)
            end
          end

         it "displays the list of top manufacturers" do
            within "#manufacturers" do
              manufacturers.each do |manufacturer|
                expect(page).to have_css("a", text: /#{manufacturer} \(\d{3}\)/i, count: 1)
              end
            end
          end
        end

        context "with all time selected" do
          before do
            page.select "All time", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @this_years_donations.values.map(&:total_quantity).sum + @last_years_donations.map(&:total_quantity).sum }
          let(:manufacturers) { [@this_years_donations.values + @last_years_donations].flatten.map(&:manufacturer).map(&:name) }

          it "has a widget displaying the Donation totals from last year, only using donations from last year" do
            within "#manufacturers" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays the list of top manufacturers" do
            within "#manufacturers" do
              manufacturers.each do |manufacturer|
                expect(page).to have_css("a", text: /#{manufacturer} \(\d{3}\)/i, count: 1)
              end
            end
          end
        end                
      end



      xcontext "inactive item" do
        it 'should not count totals for donations' do
          item = donation.storage_location.items.first
          visit subject
          expect(page).to have_content("100 items received year to date")

          item.update(active: false)
          visit subject
          expect(page).to_not have_content("100 items received year to date")
        end

        it 'should not count totals for purchases' do
          item = purchase.storage_location.items.first
          visit subject
          expect(page).to have_content("100 items received year to date")

          item.update(active: false)
          visit subject
          expect(page).to_not have_content("100 items received year to date")
        end

        it 'should not count totals for distributions' do
          item = distribution.storage_location.items.first
          visit subject
          expect(page).to have_content("100 items distributed year to date")

          item.update(active: false)
          visit subject
          expect(page).to_not have_content("100 items distributed year to date")
        end
      end

      xit "should update totals on dashboard immediately after donations and distributions are made" do
        # Verify the initial totals on dashboard
        visit subject
        expect(page).to have_content("0 items received")
        expect(page).to have_content("0 items on-hand")

        # Make a donation
        visit url_prefix + "/donations/new"
        select "Misc. Donation", from: "donation_source"
        expect(page).not_to have_xpath("//select[@id='donation_donation_site_id']")
        expect(page).not_to have_xpath("//select[@id='donation_diaper_drive_participant_id']")
        expect(page).not_to have_xpath("//select[@id='donation_manufacturer_id']")
        select StorageLocation.first.name, from: "donation_storage_location_id"
        select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
        fill_in "donation_line_items_attributes_0_quantity", with: "100"
        click_button "Save"

        # Make a diaper drive donation
        visit url_prefix + "/donations/new"
        select "Diaper Drive", from: "donation_source"
        select DiaperDriveParticipant.first.business_name, from: "donation_diaper_drive_participant_id"
        select StorageLocation.first.name, from: "donation_storage_location_id"
        select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
        fill_in "donation_line_items_attributes_0_quantity", with: "100"
        click_button "Save"

        # Make a manufacturer donation
        visit url_prefix + "/donations/new"
        select "Manufacturer", from: "donation_source"
        select Manufacturer.first.name, from: "donation_manufacturer_id"
        select StorageLocation.first.name, from: "donation_storage_location_id"
        select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
        fill_in "donation_line_items_attributes_0_quantity", with: "75"
        click_button "Save"

        # Check the dashboard now
        visit url_prefix + "/dashboard"
        expect(page).to have_content("275 items received")
        expect(page).to have_content("275 items on-hand")
        expect(page).to have_content("75 items donated year to date by 1 Manufacturer")

        # Check distributions
        visit url_prefix + "/distributions/new"
        select Partner.last.name, from: "distribution_partner_id"
        select @organization.storage_locations.first.name, from: "distribution_storage_location_id"
        select Item.last.name, from: "distribution_line_items_attributes_0_item_id"
        fill_in "distribution_line_items_attributes_0_quantity", with: "50"
        click_button "Save"
        click_on "View", match: :first
        expect(page).to have_content "Distribution Manifest for"
        expect(page).to have_xpath("//table/tbody/tr/td", text: "50")

        # Check the dashboard now
        visit url_prefix + "/dashboard"
        expect(page).to have_content("275 items received")
        expect(page).to have_content("50 items distributed")
        expect(page).to have_content("225 items on-hand")
        expect(page).to have_content("1 Diaper Drives")
      end

      xit "should list top 10 manufacturers" do
        visit url_prefix + "/dashboard"
        expect(page).to have_content("0 items donated year to date by 0 Manufacturers")

        item_qty = 200
        12.times do
          manufacturer = create(:manufacturer)
          create(:donation, :with_items, item: Item.first, item_quantity: item_qty, source: Donation::SOURCES[:manufacturer], manufacturer: manufacturer, issued_at: Time.zone.today)
          item_qty -= 1
        end

        visit url_prefix + "/dashboard"
        expect(page).to have_content("2,334 items donated year to date by 12 Manufacturers")
        expect(page).to have_content "Top Manufacturer Donations"
        expect(page).to have_css(".manufacturer", count: 10)
      end
    end
  end
end