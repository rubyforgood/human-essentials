require 'rails_helper'

RSpec.describe DashboardController, type: :controller do
  let(:default_params) {
    { organization_id: @organization.to_param }
  }

  before do
    sign_in(@user)
  end

  describe "GET #show" do
    it "returns http success" do
      get :show, params: default_params
      expect(response).to have_http_status(:success)
    end
  end

end
