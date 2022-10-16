require 'rails_helper'

RSpec.describe "Admin::UsersController", type: :request do
  let(:default_params) do
    { organization_id: @organization.id }
  end

  context "When logged in as a super admin" do
    before do
      sign_in(@super_admin)
      create(:organization)
    end

    describe "GET #new" do
      it "renders new template" do
        get new_admin_user_path
        expect(response).to render_template(:new)
      end

      it "preloads organizations" do
        get new_admin_user_path
        expect(assigns(:organizations)).to eq(Organization.all.alphabetized)
      end
    end

    describe "POST #create" do
      it "returns http success" do
        post admin_users_path, params: { user: { email: 'email@email.com', organization_id: 1 } }
        expect(response).to redirect_to(admin_users_path(organization_id: @organization.short_name))
      end

      it "preloads organizations" do
        post admin_users_path, params: { user: { organization_id: 1 } }
        expect(assigns(:organizations)).to eq(Organization.all.alphabetized)
      end
    end
  end

  context "When logged in as an organization_admin" do
    before do
      sign_in @organization_admin
      create(:organization)
    end

    describe "GET #new" do
      it "redirects" do
        get new_admin_user_path
        expect(response).to redirect_to(dashboard_path)
      end
    end

    describe "POST #create" do
      it "redirects" do
        post admin_users_path, params: { user: { organization_id: 1 } }
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end

  context "When logged in as a non-admin user" do
    before do
      sign_in @user
      create(:organization)
    end

    describe "GET #new" do
      it "redirects" do
        get new_admin_user_path
        expect(response).to redirect_to(dashboard_path)
      end
    end

    describe "POST #create" do
      it "redirects" do
        post admin_users_path, params: { user: { organization_id: 1 } }
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end
end
