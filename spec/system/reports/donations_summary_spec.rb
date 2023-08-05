RSpec.describe "DonationsSummary", type: :system, js: true do
  before do
    @url_prefix = "/#{@organization.short_name}"
  end

  context "When signed in as a normal user" do
    before do
      sign_in @user
    end

    let!(:storage_location) { create(:storage_location, :with_items, item_quantity: 0, organization: @organization) }

    test_time = Time.zone.now

    # 1, 20, 300, ..., 900000000
    # assuming each value is used once, summing these values makes easily recognizable totals
    # .fetch() from it so too-high indices raise IndexError
    # legal indices are in -8..8 (i.e., inclusive)
    item_quantities = (1..9).map { |i| i * 10**(i - 1) }

    context "when visiting the summary page" do
      it "has a link to create a new donation" do
        visit @url_prefix + "/reports/donations_summary" 
        expect(page).to have_link "New Donation", href: "#{@url_prefix}/donations/new"
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
        [nil, test_time - 2.years, test_time - rand(180).days, :set_custom_dates], # arbitrary values
        ["Today", test_time, test_time],
        ["Yesterday", test_time.yesterday, test_time.yesterday],
        ["Last 7 Days", test_time - 6.days, test_time],
        ["Last 30 Days", test_time - 29.days, test_time],
        ["This Month", test_time.beginning_of_month, test_time.end_of_month],
        ["Last Month", test_time.last_month.beginning_of_month, test_time.last_month.end_of_month],
        ["This Year", test_time.beginning_of_year, test_time.end_of_year]
        #  We now can't test the lower limit of All Time, because the earliest possible date is 2000-01-01
        #  ["All Time",     test_time - 100.years,                   test_time]
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

        context "given 1 Donation on #{before_filtered_date_range} (only if a valid date), " \
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

            # create Donations before (if valid) & after the filtered date range
            valid_bracketing_dates(date_range_info).each { create_next_donation donation_date: _1 }
          end

          describe("filtering to '#{filtered_date_range_label}'" + (set_custom_dates ? " (#{custom_dates})" : "")) do
            before do
              visit @url_prefix + "/reports/donations_summary" 
              filter_to_date_range(filtered_date_range_label, custom_dates)
            end

            expected_recent_donation_links_count = [max_recent_donation_links_count, num_donations_in_filtered_period].min

            it "shows the correct total and #{expected_recent_donation_links_count} Recent Donation link(s)" do
              total_donations = find(".total_received_donations").text.delete(",").to_i
              expect(total_donations).to eq @quantities_donated_in_filtered_date_range.sum

              recent_donation_links = all(".donation a").map(&:text)

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
  end

  def filter_to_date_range(range_name, custom_dates = nil)
    select_date_filter_range range_name

    if custom_dates.present?
      fill_in :filters_date_range, with: ""
      fill_in :filters_date_range, with: custom_dates
    end

    click_on "Filter"
  end

  def select_date_filter_range(range_name)
    find("#filters_date_range").click

    if range_name
      within ".container__predefined-ranges" do
        find("button", text: range_name).click
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