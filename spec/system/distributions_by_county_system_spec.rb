RSpec.feature "Distributions by County", type: :system do
  include_examples "distribution_by_county"

  let(:year) { Time.current.year }
  let(:issued_at_last_year) { Time.current.utc.change(year: year - 1).to_datetime }

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
      expect(page).to have_text("50", count: 4)
      expect(page).to have_text("$525.00", count: 4)
    end

    it("works for this year") do
      @distribution_current = create(:distribution, :with_items, item: item_1, organization: user.organization, partner: partner_1, issued_at: issued_at_present)
      @distribution_last_year = create(:distribution, :with_items, item: item_1, organization: user.organization, partner: partner_1, issued_at: issued_at_last_year)

      visit_distribution_by_county_with_specified_date_range("This Year")

      partner_1.profile.served_areas.each do |served_area|
        expect(page).to have_text(served_area.county.name)
      end
      expect(page).to have_text("25", count: 4)
      expect(page).to have_text("$262.50", count: 4)
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
