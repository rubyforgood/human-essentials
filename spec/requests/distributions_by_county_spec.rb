require 'rails_helper'

RSpec.describe "DistributionsByCounties", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/distributions_by_county/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/distributions_by_county/show"
      expect(response).to have_http_status(:success)
    end
  end

end
