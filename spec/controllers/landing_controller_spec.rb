require 'rails_helper'

RSpec.describe LandingController, type: :controller do
  before do
  	sign_in(@user)
  end
  describe "GET #index" do
    subject { get :index }
    it "returns http success" do
      expect(subject).to have_http_status(:success)
    end
  end
end
