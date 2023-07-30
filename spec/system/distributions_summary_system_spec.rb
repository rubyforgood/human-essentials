require "rails_helper"

RSpec.describe "Distributions Summary", type: :system, js: true do

  test_time = Time.zone.now

  before do
    sign_in(@user)
  end

  around do |example|
    travel_to(test_time)
    example.run
    travel_back
  end

  let!(:storage_location) { create(:storage_location, :with_items, item_quantity: 0, organization: @organization) }
  let(:org_short_name) { @organization.short_name }
  let(:distributions_summary_page) { OrganizationDistributionsSummaryPage.new org_short_name: org_short_name }

  it "has a link to create a new distribution" do
    org_new_distribution_page = OrganizationNewDistributionPage.new org_short_name: org_short_name

    expect(distributions_summary_page.visit).to have_distributions_section

    expect { distributions_summary_page.create_new_distribution }
      .to change { page.current_path }
      .to org_new_distribution_page.path
  end

  # 1, 20, 300, ..., 900000000
  # assuming each value is used once, summing these values makes easily recognizable totals
  # .fetch() from it so too-high indices raise IndexError
  # legal indices are in -8..8 (i.e., inclusive)
  item_quantities = (1..9).map { |i| i * 10**(i - 1) }

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
    ["All Time",     Time.zone.parse("2000-01-01"),                   test_time],
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

    context "given 1 Distribution on #{before_filtered_date_range}  (unless 'All Time'), " \
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
        @distributions_in_filtered_date_range = Array.new(num_distributions_in_filtered_period) do
          create_next_product_drive_distribution date_picker: filtered_dates.sample
        end

        # create Distributions before & after the filtered date range
        valid_bracketing_dates(date_range_info).each { create_next_product_drive_distribution date_picker: _1 }
      end

      describe("filtering to '#{filtered_date_range_label}'" + (set_custom_dates ? " (#{custom_dates})" : "")) do
        before do
          distributions_summary_page
            .visit
            .filter_to_date_range(filtered_date_range_label, custom_dates)
        end

        expected_recent_distribution_links_count = [max_recent_distribution_links_count, num_distributions_in_filtered_period].min

        it "shows the correct total and #{expected_recent_distribution_links_count} Recent Distribution link(s)" do
          expect(distributions_summary_page.total_distributed).to eq @distributions_in_filtered_date_range.map(&:quantity).sum

          recent_distribution_links = distributions_summary_page.recent_distribution_links

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
