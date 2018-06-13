RSpec.describe DashboardController, type: :controller do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  context "While signed in" do
    before do
      sign_in(@user)
    end

    describe "GET #show" do
      it "returns http success" do
        get :index, params: default_params
        expect(response).to have_http_status(:success)
      end

      context "for another org" do
        it "requires authorization" do
          # nother org
          get :index, params: { organization_id: create(:organization).to_param }
          expect(response).to be_redirect
        end
      end
    end
  end

  context "While not signed in" do
    it "redirects for authentication" do
      get :index, params: { organization_id: create(:organization).to_param }
      expect(response).to be_redirect
    end
  end
end
