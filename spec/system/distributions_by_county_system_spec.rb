RSpec.feature "Distributions by County", type: :system do
  let(:default_params) do
    {organization_id: @organization.to_param}
  end

  let(:year) { Time.current.year }
  let(:issued_at_last_year) { Time.current.utc.change(year: year - 1).to_datetime }
  let(:issued_at_present) { Time.current.utc.to_datetime }
  let(:item_1) { create(:item, value_in_cents: 1050) }

  before do
    sign_in(@user)
    setup_overlapping_partners
    @storage_location = create(:storage_location, organization: @organization)
    setup_storage_location(@storage_location)
  end

  it "shows 'Unspecified 100%' if no served_areas" do
    @distribution = create(:distribution, :with_items, item: item_1, organization: @user.organization)
    visit distributions_by_county_show_path
    expect(page).to have_text("Unspecified")
    expect(page).to have_text("100")
    expect(page).to have_text("$1,050.00")
  end

  context "basic behaviour with served areas" do
    it "shows the county names and percentages if there are served_areas" do
      @distribution = create(:distribution, :with_items, item: item_1, organization: @user.organization, partner: @partner_1)
      visit distributions_by_county_show_path
      @partner_1.profile.served_areas.each do |served_area|
        expect(page).to have_text(served_area.county.name)
      end
      expect(page).to have_text("25", count: 4)
      expect(page).to have_text("$262.50", count: 4)
    end
  end

  context "handles time ranges properly (not fully written yet)" do
    it("works for all time") do
      @distribution_last_year = create(:distribution, :with_items, item: item_1, organization: @user.organization, partner: @partner_1, issued_at: issued_at_last_year)
      @distribution_current = create(:distribution, :with_items, item: item_1, organization: @user.organization, partner: @partner_1, issued_at: issued_at_present)
      visit_distribution_by_county_with_specified_date_range("All Time")
      @partner_1.profile.served_areas.each do |served_area|
        expect(page).to have_text(served_area.county.name)
      end
      expect(page).to have_text("50", count: 4)
      expect(page).to have_text("$525.00", count: 4)
    end

    it("works for this year") do
      @distribution_current = create(:distribution, :with_items, item: item_1, organization: @user.organization, partner: @partner_1, issued_at: issued_at_present)
      @distribution_last_year = create(:distribution, :with_items, item: item_1, organization: @user.organization, partner: @partner_1, issued_at: issued_at_last_year)

      visit_distribution_by_county_with_specified_date_range("This Year")

      @partner_1.profile.served_areas.each do |served_area|
        expect(page).to have_text(served_area.county.name)
      end
      expect(page).to have_text("25", count: 4)
      expect(page).to have_text("$262.50", count: 4)
    end
  end

  it "handles multiple partners with overlapping service areas properly" do
    @distribution_p1 = create(:distribution, :with_items, item: item_1, organization: @user.organization, partner: @partner_1, issued_at: issued_at_present)
    @distribution_p2 = create(:distribution, :with_items, item: item_1, organization: @user.organization, partner: @partner_2, issued_at: issued_at_present)

    visit distributions_by_county_show_path

    expect(page).to have_text("45") # First ones are definitely combined
    expect(page).to have_text("$472.50")
    expect(page).to have_text("20")
    expect(page).to have_text("$210.00")
    @partner_1.profile.served_areas.each do |served_area|
      expect(page).to have_text(served_area.county.name)
    end
    @partner_2.profile.served_areas.each do |served_area|
      expect(page).to have_text(served_area.county.name)
    end
  end

  def setup_overlapping_partners
    @partner_1 = create(:partner, organization: @organization)
    @partner_1.profile.served_areas << create_list(:partners_served_area, 4,
      partner_profile: @partner_1.profile, client_share: 25)
    @partner_2 = create(:partner, organization: @organization)
    @partner_2.profile.served_areas << create_list(:partners_served_area, 5,
      partner_profile: @partner_1.profile, client_share: 20)
    @partner_2.profile.served_areas[0].county = @partner_1.profile.served_areas[0].county
    @partner_2.profile.served_areas[0].save
    @partner_2.reload
  end

  def visit_distribution_by_county_with_specified_date_range(date_range_string)
    visit dashboard_path(default_params)
    find("#filters_date_range").click

    within ".container__predefined-ranges" do
      find("button", text: date_range_string).click
    end

    click_on "Filter"
    click_on "Distributions by County"
  end
end
