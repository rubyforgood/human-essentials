RSpec.describe "DistributionsByCounties", type: :request do
  include_examples "distribution_by_county"

  context "While not signed in" do
    it "redirects for authentication" do
      get distributions_by_county_report_path
      expect(response).to be_redirect
    end
  end

  context "While signed in as bank" do
    before do
      sign_in(user)
    end

    it "shows 'Unspecified 100%' if no served_areas" do
      create(:distribution, :with_items, item: item_1, organization: organization)
      get distributions_by_county_report_path
      expect(response.body).to include("Unspecified")
      expect(response.body).to include("100")
      expect(response.body).to include("$1,050.00")
    end

    it "includes loose items, but not kits in item dropdown" do
      create(:distribution, :with_items, item: kit_a.item, organization: organization, partner: partner_1, issued_at: issued_at_present) #This is just to make sure the system creates the kit and items within it
      get distributions_by_county_report_path
      expect(response.body).to include (item_3.name)
      expect(response.body).to_not include(kit_a.item.name)
    end

    context "basic behaviour with served areas" do
      it "handles multiple partners with overlapping service areas properly" do
        create(:distribution, :with_items, item: item_1, organization: organization, partner: partner_1, issued_at: issued_at_present)
        create(:distribution, :with_items, item: item_1, organization: organization, partner: partner_2, issued_at: issued_at_present)

        get distributions_by_county_report_path

        expect(response.body).to include("45") # First ones are definitely combined
        expect(response.body).to include("$472.50")
        expect(response.body).to include("20")
        expect(response.body).to include("$210.00")

        # The distribution_by_county shared examples give each partner a unique set of counties,
        # except the second partner shares the first partner's first county.
        expect(response.body).to include("Partner 1 Test County 1")
        expect(response.body).to include("Partner 1 Test County 2")
        expect(response.body).to include("Partner 1 Test County 3")
        expect(response.body).to include("Partner 1 Test County 4")

        expect(response.body).to include("Partner 2 Test County 2")
        expect(response.body).to include("Partner 2 Test County 3")
        expect(response.body).to include("Partner 2 Test County 4")
        expect(response.body).to include("Partner 2 Test County 5")
      end
    end


    context "filtration, kits" do
      before do
        current_year =  Time.current.year
        issued_at_last_year =  Time.current.change(year: current_year - 1).to_datetime
        @distribution_last_year = create(:distribution, :with_items, item: kit_a.item, organization: user.organization, partner: partner_1, issued_at: issued_at_last_year)
        @distribution_current_1 = create(:distribution, :with_items, item: kit_a.item, organization: user.organization, partner: partner_1, issued_at: issued_at_present)
        @distribution_current_2 = create(:distribution, :with_items, item: item_2, organization: user.organization, partner: partner_1, issued_at: issued_at_present)
        @distribution_current_3 = create(:distribution, :with_items, item: item_4, organization: user.organization, partner: partner_1, issued_at: issued_at_present)
        @all_time_string = "January 1,1909 - January 1,9999"
      end
      it("works for all time with a reporting category") do
        reporting_category_params =  {filters: { date_range: @all_time_string, by_reporting_category: "pads", by_item_id: nil }}
        get distributions_by_county_report_path,  params: reporting_category_params

        partner_1.profile.served_areas.each do |served_area|
          expect(response.body).to include(served_area.county.name)
        end

        expect(response.body).to include("1,025").at_least(4).times
        expect(response.body).to include("$762.50").exactly(4).times
      end
      it("works for all time with an item") do
        params =  {filters: { date_range: @all_time_string, by_reporting_category: nil, by_item_id: item_3.id }}
        get distributions_by_county_report_path,  params: params

        partner_1.profile.served_areas.each do |served_area|
          expect(response.body).to include(served_area.county.name)
        end

        expect(response.body).to include("1,000").at_least(4).times
        expect(response.body).to include("$750.00").exactly(4).times
      end


    end


  end
end
