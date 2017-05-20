RSpec.describe DashboardController, type: :controller do
  let(:default_params) {
    { organization_id: @organization.to_param }
  }

  context "While signed in" do
    before do
      sign_in(@user)
    end
  
    describe "GET #show" do
      it "returns http success" do
        get :show, params: default_params
        expect(response).to have_http_status(:success)
      end

      it "requires authorization" do
        get :show, params: { organization_id: create(:organization).id }
        expect(response).to have_http_status(403)
      end
    end
  end

  context "While not signed in" do
    it "redirects for authentication" do
      get :show, params: { organization_id: create(:organization).id }
      expect(response).to be_redirect
    end
  end

end
