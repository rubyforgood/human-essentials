require "rails_helper"

RSpec.describe "DistributionsByCounties", type: :request do
  let(:default_params) do
    {organization_id: @organization.to_param}
  end

  context "While not signed in" do
    it "redirects for authentication" do
      get distributions_by_county_show_path(default_params)
      expect(response).to be_redirect
    end

    context "While signed in as bank" do
      before do
        sign_in(@user)
      end

      describe "show" do
        it "returns http success" do
          get distributions_by_county_show_path(default_params)
          expect(response).to have_http_status(:success)
        end
      end
    end
  end
end
