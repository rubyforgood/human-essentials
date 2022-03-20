require 'rails_helper'

RSpec.describe "DiaperDrives", type: :request, skip_seed: true do
  let(:default_params) do
    { organization_id: @organization.id.to_param }
  end

  context "While signed in >" do
    let(:diaper_drive) { create(:diaper_drive) }
    before do
      sign_in(@user)
    end

    describe "GET #index" do
      it "returns http success" do
        get diaper_drives_path(default_params)
        expect(response).to be_successful
      end
    end

    describe "GET #new" do
      it "returns http success" do
        get new_diaper_drive_path(default_params)
        expect(response).to be_successful
      end
    end

    describe "POST#create" do
      it "returns redirect http status" do
        post diaper_drives_path(default_params.merge(diaper_drive: attributes_for(:diaper_drive)))
        expect(response).to have_http_status(:redirect)
      end
    end

    describe "PUT#update" do
      it "returns redirect http status" do
        put diaper_drive_path(default_params.merge(id: diaper_drive.id, diaper_drive: attributes_for(:diaper_drive)))
        expect(response).to have_http_status(:redirect)
      end
    end

    describe "GET #edit" do
      it "returns http success" do
        get edit_diaper_drive_path(default_params.merge(id: diaper_drive.id))
        expect(response).to be_successful
      end
    end

    describe "GET #show" do
      it "returns http success" do
        get diaper_drive_path(default_params.merge(id: diaper_drive.id))
        expect(response).to be_successful
      end
    end

    describe "DELETE #destroy" do
      it "redirects to the index" do
        delete diaper_drive_path(default_params.merge(id: diaper_drive.id))
        expect(response).to redirect_to(diaper_drives_path)
      end
    end
  end
end
