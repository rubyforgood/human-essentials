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

    let!(:storage_location) { create(:storage_location, :with_items, item_quantity: 0, organization: @organization) }
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

    describe "Inventory Totals" do
      let(:date_to_view) { Time.zone.parse("June 1 2018") }
      let(:last_year_date) { Time.zone.parse("June 1, 2017") }
      let(:beginning_of_2018) { Time.zone.parse("January 1, 2018 12:01am") }

      describe "Summary" do
        before do
          create_list(:storage_location, 3, :with_items, item_quantity: 111, organization: @organization)
          visit subject
        end

        it "displays the on-hand totals" do
          within "#summary" do
            expect(page).to have_content("on-hand")
          end
        end

        context "when constrained to date range" do
          it "does not change" do
            within "#summary" do
              expect(page).to have_content("333")
            end

            page.select "Last Year", from: "dashboard_filter_interval"

            within "#summary" do
              expect(page).to have_content("333")
            end
          end
        end
      end

      describe "Donations" do
        around do |example|
          Timecop.travel(date_to_view) do
            example.run
          end
        end

        it "has a link to create a new donation" do
          visit subject
          expect(page).to have_css("#donations")
          within "#donations" do
            expect(page).to have_xpath("//a[@href='#{new_donation_path(organization_id: @organization.to_param)}']", visible: false)
          end
        end

        it "doesn't count inactive items" do
          item = create(:donation, :with_items, item_quantity: 100, storage_location: storage_location).items.first
          visit subject
          within "#donations" do
            expect(page).to have_content("100")
          end

          item.update!(active: false)
          visit subject

          skip "TODO: How *should* we handle this? It's failing because it's finding 100 items in a recent donation"
          within "#donations" do
            expect(page).to have_no_content("100")
          end
        end

        context "when constrained to date range" do
          before do
            @organization.donations.destroy_all

            @this_years_donations = {
              today: create(:donation, :with_items, issued_at: date_to_view, item_quantity: 100, storage_location: storage_location, organization: @organization),
              yesterday: create(:diaper_drive_donation, :with_items, issued_at: date_to_view.yesterday, item_quantity: 101, storage_location: storage_location, organization: @organization),
              earlier_this_week: create(:donation_site_donation, :with_items, issued_at: date_to_view.beginning_of_week, item_quantity: 102, storage_location: storage_location, organization: @organization),
              beginning_of_year: create(:manufacturer_donation, :with_items, issued_at: beginning_of_2018, item_quantity: 103, storage_location: storage_location, organization: @organization)
            }
            @last_years_donations = create_list(:donation, 2, :with_items, issued_at: last_year_date, item_quantity: 104, storage_location: storage_location, organization: @organization)
            visit subject
          end

          describe "This Year" do
            before do
              page.select "This Year", from: "dashboard_filter_interval"
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

          describe "Today" do
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

          describe "Yesterday" do
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

          describe "This Week" do
            before do
              page.select "This Week", from: "dashboard_filter_interval"
            end

            let(:total_inventory) { [@this_years_donations[:today], @this_years_donations[:yesterday], @this_years_donations[:earlier_this_week]].map(&:total_quantity).sum }

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

          describe "This Month" do
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

          describe "Last Month" do
            before do
              page.select "Last Month", from: "dashboard_filter_interval"
            end

            let(:total_inventory) { [@this_years_donations[:yesterday], @this_years_donations[:earlier_this_week]].map(&:total_quantity).sum }

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

          describe "Last Year" do
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

          describe "All Time" do
            before do
              page.select "All Time", from: "dashboard_filter_interval"
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
      end

      describe "Purchases" do
        around do |example|
          Timecop.travel(date_to_view) do
            example.run
          end
        end

        it "has a link to create a new purchase" do
          visit subject
          expect(page).to have_css("#purchases")
          within "#purchases" do
            expect(page).to have_xpath("//a[@href='#{new_purchase_path(organization_id: @organization.to_param)}']", visible: false)
          end
        end

        it 'does not count inactive items' do
          item = create(:purchase, :with_items, item_quantity: 100, storage_location: storage_location).items.first
          visit subject
          within "#purchases" do
            expect(page).to have_content("100")
          end

          item.update!(active: false)
          visit subject

          skip "TODO: How *should* we handle this? It's failing because it's finding 100 items in a recent purchase"
          within "#purchases" do
            expect(page).to have_no_content("100")
          end
        end

        context "when constrained to date range" do
          before do
            @organization.purchases.destroy_all
            storage_location = create(:storage_location, :with_items, item_quantity: 0, organization: @organization)
            @this_years_purchases = {
              today: create(:purchase, :with_items, issued_at: date_to_view, item_quantity: 100, storage_location: storage_location, organization: @organization),
              yesterday: create(:purchase, :with_items, issued_at: date_to_view.yesterday, item_quantity: 101, storage_location: storage_location, organization: @organization),
              earlier_this_week: create(:purchase, :with_items, issued_at: date_to_view.beginning_of_week, item_quantity: 102, storage_location: storage_location, organization: @organization),
              beginning_of_year: create(:purchase, :with_items, issued_at: beginning_of_2018, item_quantity: 103, storage_location: storage_location, organization: @organization)
            }
            @last_years_purchases = create_list(:purchase, 2, :with_items, issued_at: last_year_date, item_quantity: 104, storage_location: storage_location, organization: @organization)
            visit subject
          end

          describe "This Year" do
            before do
              page.select "This Year", from: "dashboard_filter_interval"
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

          describe "Today" do
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

          describe "Yesterday" do
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

          describe "This Week" do
            before do
              page.select "This Week", from: "dashboard_filter_interval"
            end

            let(:total_inventory) { [@this_years_purchases[:today], @this_years_purchases[:yesterday], @this_years_purchases[:earlier_this_week]].map(&:total_quantity).sum }

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

          describe "This Month" do
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

          describe "Last Month" do
            before do
              page.select "Last Month", from: "dashboard_filter_interval"
            end

            let(:total_inventory) { [@this_years_purchases[:yesterday], @this_years_purchases[:earlier_this_week]].map(&:total_quantity).sum }

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

          describe "Last Year" do
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

          describe "All Time" do
            before do
              page.select "All Time", from: "dashboard_filter_interval"
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
      end

      describe "Diaper Drives" do
        around do |example|
          Timecop.travel(date_to_view) do
            example.run
          end
        end

        it "has a widget for diaper drive summary data" do
          visit subject
          expect(page).to have_css("#diaper_drives")
        end

        context "when constrained to date range" do
          before do
            @organization.donations.destroy_all
            storage_location = create(:storage_location, :with_items, item_quantity: 0, organization: @organization)
            diaper_drive1 = create(:diaper_drive_participant, business_name: "First Diaper Drive", organization: @organization)
            diaper_drive2 = create(:diaper_drive_participant, business_name: "Second Diaper Drive", organization: @organization)

            @this_years_donations = {
              today: create(:diaper_drive_donation, :with_items, diaper_drive_participant: diaper_drive1, issued_at: date_to_view, item_quantity: 100, storage_location: storage_location, organization: @organization),
              yesterday: create(:diaper_drive_donation, :with_items, diaper_drive_participant: diaper_drive2, issued_at: date_to_view.yesterday, item_quantity: 101, storage_location: storage_location, organization: @organization),
              earlier_this_week: create(:diaper_drive_donation, :with_items, diaper_drive_participant: diaper_drive1, issued_at: date_to_view.beginning_of_week, item_quantity: 102, storage_location: storage_location, organization: @organization),
              beginning_of_year: create(:diaper_drive_donation, :with_items, diaper_drive_participant: diaper_drive2, issued_at: beginning_of_2018, item_quantity: 103, storage_location: storage_location, organization: @organization)
            }

            @last_years_donations = create_list(:diaper_drive_donation, 2, :with_items, diaper_drive_participant: diaper_drive1, issued_at: last_year_date, item_quantity: 104, storage_location: storage_location, organization: @organization)
            visit subject
          end

          describe "This Year" do
            before do
              page.select "This Year", from: "dashboard_filter_interval"
            end

            let(:total_inventory) { @this_years_donations.values.map(&:total_quantity).sum }

            it "has a widget displaying the year-to-date Diaper drive totals, only using donations from this year" do
              within "#diaper_drives" do
                expect(page).to have_content(/2 diaper drive/i)
                expect(page).to have_content(total_inventory)
              end
            end

            it "displays some recent donations" do
              within "#diaper_drives" do
                expect(page).to have_css("a", text: /10\d from (first|second) diaper drive/i, count: 3)
              end
            end
          end

          describe "Today" do
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

          describe "Yesterday" do
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

          describe "This Week" do
            before do
              page.select "This Week", from: "dashboard_filter_interval"
            end

            let(:total_inventory) { [@this_years_donations[:today], @this_years_donations[:yesterday], @this_years_donations[:earlier_this_week]].map(&:total_quantity).sum }

            it "has a widget displaying the Diaper drive totals from this week, only using donations from this week" do
              within "#diaper_drives" do
                expect(page).to have_content(/2 diaper drive/i)
                expect(page).to have_content(total_inventory)
              end
            end

            it "displays some recent donations" do
              within "#diaper_drives" do
                expect(page).to have_css("a", text: /10\d from (first|second) diaper drive/i, count: 3)
              end
            end
          end

          describe "This Month" do
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

          describe "Last Month" do
            before do
              page.select "Last Month", from: "dashboard_filter_interval"
            end

            let(:total_inventory) { [@this_years_donations[:yesterday], @this_years_donations[:earlier_this_week]].map(&:total_quantity).sum }

            it "has a widget displaying the Diaper drive totals from last month, only using donations from last month" do
              within "#diaper_drives" do
                expect(page).to have_content(/2 diaper drive/i)
                expect(page).to have_content(total_inventory)
              end
            end

            it "displays some recent donations" do
              within "#diaper_drives" do
                expect(page).to have_css("a", text: /10\d from (first|second) diaper drive/i, count: 2)
              end
            end
          end

          describe "Last Year" do
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

          describe "All Time" do
            before do
              page.select "All Time", from: "dashboard_filter_interval"
            end

            let(:total_inventory) { @this_years_donations.values.map(&:total_quantity).sum + @last_years_donations.map(&:total_quantity).sum }

            it "has a widget displaying the Diaper drive totals from last year, only using donations from last year" do
              within "#diaper_drives" do
                expect(page).to have_content(total_inventory)
                expect(page).to have_content(/2 diaper drive/i)
              end
            end

            it "displays some recent donations from that time" do
              within "#diaper_drives" do
                expect(page).to have_css("a", text: /10\d from (first|second) diaper drive/i, count: 3)
              end
            end
          end
        end
      end

      describe "Manufacturer Donations" do
        around do |example|
          Timecop.travel(date_to_view) do
            example.run
          end
        end

        it "should list top 10 manufacturers" do
          visit subject

          within "#manufacturers" do
            expect(page).to have_content("0 items")
              .and have_content("0 Manufacturers")
          end

          item_qty = 200
          12.times do
            manufacturer = create(:manufacturer)
            create(:donation, :with_items, item: Item.first, item_quantity: item_qty, source: Donation::SOURCES[:manufacturer], manufacturer: manufacturer, issued_at: Time.zone.today)
            item_qty -= 1
          end

          visit subject

          within "#manufacturers" do
            expect(page).to have_content("2,334")
            expect(page).to have_content("12 Manufacturers")
            expect(page).to have_css(".manufacturer", count: 10)
          end
        end

        it "has a link to create a new donation" do
          visit subject
          expect(page).to have_css("#manufacturers")
        end

        it "doesn't count inactive items" do
          item = create(:manufacturer_donation, :with_items, item_quantity: 100, storage_location: storage_location).items.first
          visit subject
          within "#manufacturers" do
            expect(page).to have_content("100")
          end

          item.update!(active: false)
          visit subject

          skip "TODO: How *should* we handle this? It's failing because it's finding 100 items in a recent donation"
          within "#donations" do
            expect(page).to have_no_content("100")
          end
        end

        context "when constrained to date range" do
          before do
            @organization.donations.destroy_all
            storage_location = create(:storage_location, :with_items, item_quantity: 0, organization: @organization)
            manufacturer1 = create(:manufacturer, name: "ABC Corp", organization: @organization)
            manufacturer2 = create(:manufacturer, name: "BCD Corp", organization: @organization)
            manufacturer3 = create(:manufacturer, name: "CDE Corp", organization: @organization)
            manufacturer4 = create(:manufacturer, name: "DEF Corp", organization: @organization)

            @this_years_donations = {
              today: create(:manufacturer_donation, :with_items, manufacturer: manufacturer1, issued_at: date_to_view, item_quantity: 100, storage_location: storage_location, organization: @organization),
              yesterday: create(:manufacturer_donation, :with_items, manufacturer: manufacturer2, issued_at: date_to_view.yesterday, item_quantity: 101, storage_location: storage_location, organization: @organization),
              earlier_this_week: create(:manufacturer_donation, :with_items, manufacturer: manufacturer3, issued_at: date_to_view.beginning_of_week, item_quantity: 102, storage_location: storage_location, organization: @organization),
              beginning_of_year: create(:manufacturer_donation, :with_items, manufacturer: manufacturer4, issued_at: beginning_of_2018, item_quantity: 103, storage_location: storage_location, organization: @organization)
            }
            @last_years_donations = create_list(:manufacturer_donation, 2, :with_items, manufacturer: manufacturer1, issued_at: last_year_date, item_quantity: 104, storage_location: storage_location, organization: @organization)
            visit subject
          end

          describe "This Year" do
            before do
              page.select "This Year", from: "dashboard_filter_interval"
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

          describe "Today" do
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

          describe "Yesterday" do
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

          describe "This Week" do
            before do
              page.select "This Week", from: "dashboard_filter_interval"
            end

            let(:total_inventory) { [@this_years_donations[:today], @this_years_donations[:yesterday], @this_years_donations[:earlier_this_week]].map(&:total_quantity).sum }
            let(:manufacturers) { [@this_years_donations[:today], @this_years_donations[:yesterday], @this_years_donations[:earlier_this_week]].map(&:manufacturer).map(&:name) }

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

          describe "This Month" do
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

          describe "Last Month" do
            before do
              page.select "Last Month", from: "dashboard_filter_interval"
            end

            let(:total_inventory) { [@this_years_donations[:yesterday], @this_years_donations[:earlier_this_week]].map(&:total_quantity).sum }
            let(:manufacturers) { [@this_years_donations[:yesterday], @this_years_donations[:earlier_this_week]].map(&:manufacturer).map(&:name) }

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

          describe "Last Year" do
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

          describe "All Time" do
            before do
              page.select "All Time", from: "dashboard_filter_interval"
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
      end

      describe "Distributions" do
        around do |example|
          Timecop.travel(date_to_view) do
            example.run
          end
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
            beginning_of_year: create(:distribution, :with_items, partner: partner4, issued_at: beginning_of_2018, item_quantity: 13, storage_location: storage_location, organization: @organization)
          }
          @last_years_distributions = create_list(:distribution, 2, :with_items, partner: partner1, issued_at: last_year_date, item_quantity: 14, storage_location: storage_location, organization: @organization)
          visit subject
        end

        it "has a link to create a new distribution" do
          expect(page).to have_css("#distributions")
          within "#distributions" do
            expect(page).to have_xpath("//a[@href='#{new_distribution_path(organization_id: @organization.to_param)}']")
          end
        end

        it "doesn't count inactive items" do
          item = create(:inventory_item, quantity: 100, storage_location: storage_location).item
          create(:distribution, :with_items, item: item, item_quantity: 100, storage_location: storage_location)
          visit subject
          within "#distributions" do
            expect(page).to have_content("100")
          end

          item.update!(active: false)
          visit subject

          skip "TODO: How *should* we handle this? It's failing because it's finding 100 items in a recent distribution"
          within "#distributions" do
            expect(page).to have_no_content("100")
          end

          item = distribution.storage_location.items.first
          visit subject
          expect(page).to have_content("100 items distributed This Year")

          item.update(active: false)
          visit subject
          expect(page).to_not have_content("100 items distributed This Year")
        end

        context "with year-to-date selected" do
          before do
            page.select "This Year", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @this_years_distributions.values.map(&:line_items).flatten.map(&:quantity).sum }
          let(:partners) { @this_years_distributions.values.map(&:partner).map(&:name) }

          it "has a widget displaying the year-to-date distribution totals, only using distributions from this year" do
            within "#distributions" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent distributions" do
            within "#distributions" do
              expect(page).to have_css("a", text: /1\d items.*(#{partners.join('|')})/i, count: 3)
            end
          end
        end

        context "with today selected" do
          before do
            page.select "Today", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @this_years_distributions[:today].line_items.total }
          let(:partner) { @this_years_distributions[:today].partner.name }

          it "has a widget displaying today's distributions totals, only using distributions from today" do
            within "#distributions" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent distributions" do
            within "#distributions" do
              expect(page).to have_css("a", text: /1\d items.*#{partner}/i, count: 1)
            end
          end
        end

        context "with yesterday selected" do
          before do
            page.select "Yesterday", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @this_years_distributions[:yesterday].line_items.total }
          let(:partner) { @this_years_distributions[:yesterday].partner.name }

          it "has a widget displaying the distributions totals from yesterday, only using distributions from yesterday" do
            within "#distributions" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent distributions" do
            within "#distributions" do
              expect(page).to have_css("a", text: /1\d items.*#{partner}/i, count: 1)
            end
          end
        end

        context "with this week selected" do
          before do
            page.select "This Week", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { [@this_years_distributions[:today], @this_years_distributions[:yesterday], @this_years_distributions[:earlier_this_week]].map(&:line_items).flatten.map(&:quantity).sum }
          let(:partners) { [@this_years_distributions[:today], @this_years_distributions[:yesterday], @this_years_distributions[:earlier_this_week]].map(&:partner).map(&:name) }

          it "has a widget displaying the distributions totals from this week, only using distributions from this week" do
            within "#distributions" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent distributions" do
            within "#distributions" do
              partners.each do |partner|
                expect(page).to have_css("a", text: /1\d items.*#{partner}/i, count: 1)
              end
            end
          end
        end

        context "with this month selected" do
          before do
            page.select "This Month", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @this_years_distributions[:today].line_items.total }
          let(:partner) { @this_years_distributions[:today].partner.name }

          it "has a widget displaying the distributions totals from this month, only using distributions from this month" do
            within "#distributions" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent distributions" do
            within "#distributions" do
              expect(page).to have_css("a", text: /1\d items.*#{partner}/i, count: 1)
            end
          end
        end

        context "with last month selected" do
          before do
            page.select "Last Month", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { [@this_years_distributions[:yesterday], @this_years_distributions[:earlier_this_week]].map(&:line_items).flatten.map(&:quantity).sum }
          let(:partners) { [@this_years_distributions[:yesterday], @this_years_distributions[:earlier_this_week]].map(&:partner).map(&:name) }

          it "has a widget displaying the distributions totals from last month, only using distributions from last month" do
            within "#distributions" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent distributions" do
            within "#distributions" do
              partners.each do |partner|
                expect(page).to have_css("a", text: /1\d items.*#{partner}/i, count: 1)
              end
            end
          end
        end

        context "with last year selected" do
          before do
            page.select "Last Year", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @last_years_distributions.map(&:line_items).flatten.map(&:quantity).sum }
          let(:partners) { @last_years_distributions.map(&:partner).map(&:name) }

          it "has a widget displaying the distributions totals from last year, only using distributions from last year" do
            within "#distributions" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent distributions from that time" do
            within "#distributions" do
              expect(page).to have_css("a", text: /1\d items.*(#{partners.join('|')})/i, count: 2)
            end
          end
        end

        context "with All Time selected" do
          before do
            page.select "All Time", from: "dashboard_filter_interval"
          end

          let(:total_inventory) { @this_years_distributions.values.map(&:line_items).flatten.map(&:quantity).sum + @last_years_distributions.map(&:line_items).flatten.map(&:quantity).sum }
          let(:partners) { [@this_years_distributions.values + @last_years_distributions].flatten.map(&:partner).map(&:name) }

          it "has a widget displaying the distributions totals from last year, only using distributions from last year" do
            within "#distributions" do
              expect(page).to have_content(total_inventory)
            end
          end

          it "displays some recent distributions from that time" do
            within "#distributions" do
              expect(page).to have_css("a", text: /1\d items.*(#{partners.join('|')})/i, count: 3)
            end
          end
        end
      end
    end
  end
end