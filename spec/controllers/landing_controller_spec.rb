require 'rails_helper'

RSpec.describe LandingController, type: :controller do

  describe "Not signed in" do

    describe "GET #index" do
      subject { get :index }
      it "returns http success" do
        expect(subject).to be_successful
      end
      it "renders the landing index" do
        expect(subject).to render_template :index
      end
    end

  end

  describe "Signed in" do

    before do
    	sign_in(@user)
    end

    describe "GET #index" do
      subject { get :index }
      it "redirects to organization dashboard" do
        expect(subject).to redirect_to(dashboard_url(@organization))
      end
    end

  end

end
