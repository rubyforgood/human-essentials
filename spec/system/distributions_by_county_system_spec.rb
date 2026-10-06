RSpec.feature "Distributions by County", type: :system do
  include_examples "distribution_by_county"

  let(:current_year) { Time.current.year }
  let(:issued_at_last_year) { Time.current.change(year: current_year - 1).to_datetime }

  before do
    sign_in(user)
    @storage_location = create(:storage_location, organization: organization)
    setup_storage_location(@storage_location)
  end

  context "with only 'loose' items" do
    context "handles time ranges properly" do
      context "all time" do
        before do
          @distribution_last_year = create(:distribution, :with_items, item: item_1, organization: user.organization, partner: partner_1, issued_at: issued_at_last_year)
          @distribution_current_1 = create(:distribution, :with_items, item: item_1, organization: user.organization, partner: partner_1, issued_at: issued_at_present)
          @distribution_current_2 = create(:distribution, :with_items, item: item_2, organization: user.organization, partner: partner_1, issued_at: issued_at_present)
        end

        it("works for all time with no reporting categories") do
          visit_distribution_by_county_with_specified_filters("All time", nil, nil)
          partner_1.profile.served_areas.each do |served_area|
            expect(page).to have_text(served_area.county.name)
          end

          expect(page).to have_css("table tbody tr td", text: "75", exact_text: true, count: 4)
          expect(page).to have_css("table tbody tr td", text: "$530.00", exact_text: true, count: 4)
        end
      end

      it("works for this year with no reporting categories") do
        @distribution_current = create(:distribution, :with_items, item: item_1, organization: user.organization, partner: partner_1, issued_at: issued_at_present)
        @distribution_last_year = create(:distribution, :with_items, item: item_1, organization: user.organization, partner: partner_1, issued_at: issued_at_last_year)

        visit_distribution_by_county_with_specified_filters("This year", nil, nil)

        partner_1.profile.served_areas.each do |served_area|
          expect(page).to have_text(served_area.county.name)
        end

        expect(page).to have_css("table tbody tr td", text: "25", exact_text: true, count: 4)
        expect(page).to have_css("table tbody tr td", text: "$262.50", exact_text: true, count: 4)
      end

      it("works for this year with reporting categories") do
        @distribution_current_1 = create(:distribution, :with_items, item: item_1, organization: user.organization, partner: partner_1, issued_at: issued_at_present)
        @distribution_current_2 = create(:distribution, :with_items, item: item_2, organization: user.organization, partner: partner_1, issued_at: issued_at_present)

        @distribution_last_year = create(:distribution, :with_items, item: item_1, organization: user.organization, partner: partner_1, issued_at: issued_at_last_year)

        visit_distribution_by_county_with_specified_filters("This year", "Cloth Diapers", nil)

        partner_1.profile.served_areas.each do |served_area|
          expect(page).to have_text(served_area.county.name)
        end

        expect(page).to have_css("table tbody tr td", text: "25", exact_text: true, count: 4)
        expect(page).to have_css("table tbody tr td", text: "$262.50", exact_text: true, count: 4)
      end

      it("works for all time with reporting categories") do
        @distribution_current_1 = create(:distribution, :with_items, item: item_1, organization: user.organization, partner: partner_1, issued_at: issued_at_present)
        @distribution_current_2 = create(:distribution, :with_items, item: item_2, organization: user.organization, partner: partner_1, issued_at: issued_at_present)

        @distribution_last_year = create(:distribution, :with_items, item: item_1, organization: user.organization, partner: partner_1, issued_at: issued_at_last_year)

        visit_distribution_by_county_with_specified_filters("All time", "Cloth Diapers", nil)

        partner_1.profile.served_areas.each do |served_area|
          expect(page).to have_text(served_area.county.name)
        end

        expect(page).to have_css("table tbody tr td", text: "50", exact_text: true, count: 4)
        expect(page).to have_css("table tbody tr td", text: "$525.00", exact_text: true, count: 4)
      end

      it("works for prior year") do
        # Should NOT return distribution issued before previous calendar year
        last_day_of_two_years_ago = Time.current.beginning_of_day.change(year: current_year - 2, month: 12, day: 31).to_datetime
        create(:distribution, :with_items, item: item_1, organization: user.organization, partner: partner_1, issued_at: last_day_of_two_years_ago)

        # Should return distribution issued during previous calendar year
        one_year_ago = issued_at_last_year
        create(:distribution, :with_items, item: item_1, organization: user.organization, partner: partner_1, issued_at: one_year_ago)

        # Should NOT return distribution issued after previous calendar year
        first_day_of_current_year = Time.current.end_of_day.change(year: current_year, month: 1, day: 1).to_datetime
        create(:distribution, :with_items, item: item_1, organization: user.organization, partner: partner_1, issued_at: first_day_of_current_year)

        visit_distribution_by_county_with_specified_filters("Prior year", nil, nil)

        partner_1.profile.served_areas.each do |served_area|
          expect(page).to have_text(served_area.county.name)
        end
        expect(page).to have_css("table tbody tr td", text: "25", exact_text: true, count: 4)
        expect(page).to have_css("table tbody tr td", text: "$262.50", exact_text: true, count: 4)
      end

      it("works for last 12 months") do
        # Should NOT return disitribution issued before 12 months ago
        one_year_and_one_day_ago = 1.year.ago.prev_day.beginning_of_day.to_datetime
        create(:distribution, :with_items, item: item_1, organization: user.organization, partner: partner_1, issued_at: one_year_and_one_day_ago)

        # Should return distribution issued during previous 12 months
        today = issued_at_present
        create(:distribution, :with_items, item: item_1, organization: user.organization, partner: partner_1, issued_at: today)

        # Should NOT return distribution issued in the future
        tomorrow = 1.day.from_now.end_of_day.to_datetime
        create(:distribution, :with_items, item: item_1, organization: user.organization, partner: partner_1, issued_at: tomorrow)

        visit_distribution_by_county_with_specified_filters("Last 12 months", nil, nil)

        partner_1.profile.served_areas.each do |served_area|
          expect(page).to have_text(served_area.county.name)
        end
        expect(page).to have_css("table tbody tr td", text: "25", exact_text: true, count: 4)
        expect(page).to have_css("table tbody tr td", text: "$262.50", exact_text: true, count: 4)
      end
    end
  end

  context "with kits" do
    context "with reporting category" do
      it "works for all time" do
        @distribution_current_1 = create(:distribution, :with_items, item: kit_a, organization: user.organization, partner: partner_1, issued_at: issued_at_present)
        @distribution_current_2 = create(:distribution, :with_items, item: item_2, organization: user.organization, partner: partner_1, issued_at: issued_at_present)
        @distribution_last_year_1 = create(:distribution, :with_items, item: kit_a, organization: user.organization, partner: partner_1, issued_at: issued_at_last_year)
        @distribution_last_year_2 = create(:distribution, :with_items, item: item_4, organization: user.organization, partner: partner_1, issued_at: issued_at_last_year)
        visit_distribution_by_county_with_specified_filters("All time", "Pads", nil)

        partner_1.profile.served_areas.each do |served_area|
          expect(page).to have_text(served_area.county.name)
        end

        expect(page).to have_css("table tbody tr td", text: "1,025", exact_text: true, count: 4)
        expect(page).to have_css("table tbody tr td", text: "$762.50", exact_text: true, count: 4)
      end
    end

    context "with item filter" do
      it "works for all time" do
        @distribution_current_1 = create(:distribution, :with_items, item: kit_a, organization: user.organization, partner: partner_1, issued_at: issued_at_present)
        @distribution_current_2 = create(:distribution, :with_items, item: item_2, organization: user.organization, partner: partner_1, issued_at: issued_at_present)
        @distribution_last_year_1 = create(:distribution, :with_items, item: kit_a, organization: user.organization, partner: partner_1, issued_at: issued_at_last_year)
        @distribution_last_year_2 = create(:distribution, :with_items, item: item_4, organization: user.organization, partner: partner_1, issued_at: issued_at_last_year)
        visit_distribution_by_county_with_specified_filters("All time", nil, item_3.name)

        partner_1.profile.served_areas.each do |served_area|
          expect(page).to have_text(served_area.county.name)
        end

        expect(page).to have_css("table tbody tr td", text: "1,000", exact_text: true, count: 4)
        expect(page).to have_css("table tbody tr td", text: "$750.00", exact_text: true, count: 4)
      end
    end
  end

  def visit_distribution_by_county_with_specified_filters(date_range_string, reporting_category, item_name)
    visit dashboard_path

    # Reports are reached through the hub now, not a sidebar group of fifteen.
    find("#essentials-sidebar").click_link("Reports")
    within("#reports-distributions") { click_on "By county" }

    # Each step checks the URL carries its filter, so a filter that never applied fails at its own
    # step instead of later on a table count. Turbo writes the URL just *before* it renders the
    # frame, so this confirms the response arrived, not that the table is up to date -- the content
    # assertions retry for that. (The CI failure that prompted this was not a wait at all: see the
    # comment on the fake clock in layouts/_essentials_head.html.erb.)
    select_date_range_preset date_range_string
    expect_filter_applied("date_range_label", date_range_string)

    if reporting_category
      open_filters
      select reporting_category, from: "NDBN reporting category"
      expect_filter_applied("by_reporting_category", find_field("NDBN reporting category").value)
    end

    if item_name
      open_filters
      select item_name, from: "Item"
      expect_filter_applied("by_item_id", find_field("Item").value)
    end
  end

  def expect_filter_applied(name, value)
    wait_for_filters
    expect(page).to have_current_path(/#{Regexp.escape(URI.encode_www_form("filters[#{name}]" => value))}(&|\z)/)
  end
end
