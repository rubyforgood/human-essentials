require "rails_helper"

RSpec.describe "Static", type: :request do
  describe "Not signed in" do
    describe "GET #index" do
      it "returns http success" do
        get root_path
        expect(response).to be_successful
      end
      it "renders the static index" do
        get root_path
        expect(response).to render_template :index
      end
    end

    describe "GET #page/privacypolicy" do
      it "renders the contact page" do
        get privacypolicy_path
        expect(response).to render_template :privacypolicy
      end
    end
  end

  describe "Signed in" do
    before do
      sign_in(@user)
    end

    describe "GET #index" do
      it "redirects to organization dashboard" do
        get root_path
        expect(response).to redirect_to(dashboard_url(@organization))
      end
    end
  end

  describe "Super user without org signed in" do
    before do
      sign_in(@super_admin_no_org)
    end

    describe "GET #index" do
      it "redirects to admin dashboard" do
        get root_path
        expect(response).to redirect_to(admin_dashboard_url(@admin))
      end
    end
  end
end
