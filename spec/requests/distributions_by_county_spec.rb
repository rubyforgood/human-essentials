RSpec.describe "DistributionsByCounties", type: :request do
  include_examples "distribution_by_county"

  context "While not signed in" do
    it "redirects for authentication" do
      get distributions_by_county_report_path
      expect(response).to be_redirect
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

      context "basic behaviour with served areas" do
        it "handles multiple partners with overlapping service areas properly" do
          create(:distribution, :with_items, item: item_1, organization: organization, partner: partner_1, issued_at: issued_at_present)
          create(:distribution, :with_items, item: item_1, organization: organization, partner: partner_2, issued_at: issued_at_present)

          get distributions_by_county_report_path

          expect(response.body).to include("45") # First ones are definitely combined
          expect(response.body).to include("$472.50")
          expect(response.body).to include("20")
          expect(response.body).to include("$210.00")
          partner_1.profile.served_areas.each do |served_area|
            expect(response.body).to include(served_area.county.name)
          end
          partner_2.profile.served_areas.each do |served_area|
            expect(response.body).to include(served_area.county.name)
          end
        end
      end
    end
  end
end
