require "rails_helper"

RSpec.describe UsersController, type: :controller do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  before do
    sign_in(@user)
  end

  describe "GET #new" do
    it "returns http success" do
      get :new, params: default_params
      expect(response).to have_http_status(:success)
    end
  end
end
