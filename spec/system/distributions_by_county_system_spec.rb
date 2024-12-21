RSpec.feature "Distributions by County", type: :system do
  include_examples "distribution_by_county"

  let(:current_year) { Time.current.year }
  let(:issued_at_last_year) { Time.current.change(year: current_year - 1).to_datetime }

  before do
    sign_in(user)
    @storage_location = create(:storage_location, organization: organization)
    setup_storage_location(@storage_location)
  end

  context "handles time ranges properly" do
    it("works for all time") do
      @distribution_last_year = create(:distribution, :with_items, item: item_1, organization: user.organization, partner: partner_1, issued_at: issued_at_last_year)
      @distribution_current = create(:distribution, :with_items, item: item_1, organization: user.organization, partner: partner_1, issued_at: issued_at_present)
      visit_distribution_by_county_with_specified_date_range("All Time")
      partner_1.profile.served_areas.each do |served_area|
        expect(page).to have_text(served_area.county.name)
      end

      expect(page).to have_css("table tbody tr td", text: "50", exact_text: true, count: 4)
      expect(page).to have_css("table tbody tr td", text: "$525.00", exact_text: true, count: 4)
    end

    it("works for this year") do
      @distribution_current = create(:distribution, :with_items, item: item_1, organization: user.organization, partner: partner_1, issued_at: issued_at_present)
      @distribution_last_year = create(:distribution, :with_items, item: item_1, organization: user.organization, partner: partner_1, issued_at: issued_at_last_year)

      visit_distribution_by_county_with_specified_date_range("This Year")

      partner_1.profile.served_areas.each do |served_area|
        expect(page).to have_text(served_area.county.name)
      end

      expect(page).to have_css("table tbody tr td", text: "25", exact_text: true, count: 4)
      expect(page).to have_css("table tbody tr td", text: "$262.50", exact_text: true, count: 4)
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

      visit_distribution_by_county_with_specified_date_range("Prior Year")

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

      visit_distribution_by_county_with_specified_date_range("Last 12 Months")

      partner_1.profile.served_areas.each do |served_area|
        expect(page).to have_text(served_area.county.name)
      end
      expect(page).to have_css("table tbody tr td", text: "25", exact_text: true, count: 4)
      expect(page).to have_css("table tbody tr td", text: "$262.50", exact_text: true, count: 4)
    end
  end

  def visit_distribution_by_county_with_specified_date_range(date_range_string)
    visit dashboard_path

    click_on "Reports"
    find(".menu-open a", text: "Distributions - By County")
    click_on "Distributions - By County"

    find("#filters_date_range").click

    within ".container__predefined-ranges" do
      find("button", text: date_range_string).click
    end

    click_on "Filter"
  end
end
