require 'rails_helper'

RSpec.describe "ProductDrives", type: :request do
  let(:default_params) do
    { organization_id: @organization.id.to_param }
  end

  context "While signed in >" do
    let(:product_drive) { create(:product_drive) }
    before do
      sign_in(@user)
    end

    describe "GET #index" do
      it "returns http success" do
        get product_drives_path(default_params)
        expect(response).to be_successful
      end
    end

    describe "GET #new" do
      it "returns http success" do
        get new_product_drive_path(default_params)
        expect(response).to be_successful
      end
    end

    describe "POST#create" do
      it "returns redirect http status" do
        post product_drives_path(default_params.merge(product_drive: attributes_for(:product_drive)))
        expect(response).to have_http_status(:redirect)
      end
    end

    describe "PUT#update" do
      it "returns redirect http status" do
        put product_drive_path(default_params.merge(id: product_drive.id, product_drive: attributes_for(:product_drive)))
        expect(response).to have_http_status(:redirect)
      end
    end

    describe "GET #edit" do
      it "returns http success" do
        get edit_product_drive_path(default_params.merge(id: product_drive.id))
        expect(response).to be_successful
      end
    end

    describe "GET #show" do
      it "returns http success" do
        get product_drive_path(default_params.merge(id: product_drive.id))
        expect(response).to be_successful
      end
    end

    describe "DELETE #destroy" do
      it "redirects to the index" do
        delete product_drive_path(default_params.merge(id: product_drive.id))
        expect(response).to redirect_to(product_drives_path)
      end
    end
  end
end
