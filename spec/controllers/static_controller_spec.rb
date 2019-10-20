require "rails_helper"

RSpec.describe StaticController, type: :controller do
  describe "Not signed in" do
    describe "GET #index" do
      subject { get :index }
      it "returns http success" do
        expect(subject).to be_successful
      end
      it "renders the static index" do
        expect(subject).to render_template :index
      end
    end

    describe "GET #page/register" do
      subject { get :register }
      it "renders the contact page" do
        expect(subject).to render_template :register
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

  describe "Super user without org signed in" do
    before do
      sign_in(@super_admin_no_org)
    end

    describe "GET #index" do
      subject { get :index }
      it "redirects to admin dashboard" do
        expect(subject).to redirect_to(admin_dashboard_url)
      end
    end
  end
end
