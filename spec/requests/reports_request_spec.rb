require 'rails_helper'

RSpec.describe "Reports", type: :request do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  context "While signed in" do
    before do
      sign_in(@user)
    end

    describe "GET /index" do
      it "returns http success" do
        get reports_path(default_params)
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /show" do
      it "returns http success" do
        get "#{reports_path(default_params)}/2018"
        expect(response).to have_http_status(:success)
      end

      it "return not found if the year params is not number" do
        expect do
          get "#{reports_path(default_params)}/test"
        end.to raise_error(ActionController::RoutingError)
      end
    end
  end
end
