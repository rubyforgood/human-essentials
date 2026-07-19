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
    end
  end
end
