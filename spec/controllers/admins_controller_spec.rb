require 'rails_helper'

RSpec.describe AdminsController, type: :controller do
  let(:default_params) {
    { organization_id: @organization.id }
  }

  context "When logged in as an organization admin" do
    before do
      sign_in(@organization_admin)
    end

    describe "GET #new" do
      it "returns http success" do
        get :new
        expect(response).to be_successful
      end
    end

    describe "POST #create" do
      it "redirects" do
        post :create, params: { organization: attributes_for(:organization) }
        expect(response).to be_redirect
      end
    end

    describe "GET #index" do
      it "returns http success" do
        get :index
        expect(response).to be_successful
      end
    end

    describe "GET #show" do
      it "returns http success" do
        get :show, params: { id: @organization.id }
        expect(response).to be_successful
      end
    end

    describe "GET #edit" do
      it "returns http success" do
        get :edit, params: { id: @organization.id }
        expect(response).to be_successful
      end
    end

    describe "PUT #update" do
      it "redirect" do
        put :update, params: { id: @organization.id, organization: { name: "Foo" } }
        expect(response).to be_redirect
      end
    end

    describe "DELETE #destroy" do
      it "does not exist" do
        expect {
          delete :destroy, params: { id: @organization.id }
        }.to raise_exception(ActionController::UrlGenerationError)
      end
    end
  end

  context "When logged in as a non-admin user" do
    before do
      sign_in(@user)
    end

    describe "GET #new" do
      it "denies access" do
        get :new
        expect(response.status).to eq(403)
      end
    end

    describe "POST #create" do
      it "returns http success" do
        post :create, params: { organization: attributes_for(:organization) }
        expect(response.status).to eq(403)
      end
    end

    describe "GET #index" do
      it "denies access" do
        get :index
        expect(response.status).to eq(403)
      end
    end

    describe "GET #edit" do
      it "denies access" do
        get :edit, params: { id: @organization.id }
        expect(response.status).to eq(403)
      end
    end

    describe "PUT #update" do
      it "redirect" do
        put :update, params: { id: @organization.id, organization: { name: "Foo" } }
        expect(response.status).to eq(403)
      end
    end
  end

end
