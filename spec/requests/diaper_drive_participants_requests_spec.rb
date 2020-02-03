require 'rails_helper'

RSpec.describe "DiaperDriveParticipants", type: :request do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  context "While signed in" do
    before do
      sign_in(@user)
    end

    describe "GET #index" do
      it "returns http success" do
        get diaper_drive_participants_path(default_params)
        expect(response).to be_successful
      end
    end

    describe "GET #new" do
      it "returns http success" do
        get new_diaper_drive_participant_path(default_params)
        expect(response).to be_successful
      end
    end

    describe "GET #edit" do
      it "returns http success" do
        get edit_diaper_drive_participant_path(default_params.merge(id: create(:diaper_drive_participant, organization: @user.organization)))
        expect(response).to be_successful
      end
    end

    describe "POST #import_csv" do
      let(:model_class) { DiaperDriveParticipant }
      it_behaves_like "csv import"
    end

    describe "GET #show" do
      it "returns http success" do
        get diaper_drive_participant_path(default_params.merge(id: create(:diaper_drive_participant, organization: @organization)))
        expect(response).to be_successful
      end
    end

    describe "DELETE #destroy" do
      it "does not have a route for this" do
        delete diaper_drive_participant_path(default_params.merge(id: create(:diaper_drive_participant)))
        expect (response).to raise_error(ActionController::RoutingError)
      end
    end

    describe "XHR #create" do
      it "successful create" do
        post diaper_drive_participants_path(default_params.merge(diaper_drive_participant: { name: "test", email: "123@mail.ru" }, xhr: true))
        expect(response).to be_successful
      end

      it "flash error" do
        post diaper_drive_participants_path(default_params.merge(diaper_drive_participant: { name: "test" }, xhr: true))
        expect(response).to be_successful
        expect(response).to have_error(/try again/i)
      end
    end

    describe "POST #create" do
      it "successful create" do
        post diaper_drive_participants_path(default_params.merge(diaper_drive_participant: { business_name: "businesstest",
                                                                               contact_name: "test", email: "123@mail.ru" }))
        expect(response).to redirect_to(diaper_drive_participants_path)
        expect(response).to have_notice(/added!/i)
      end

      it "flash error" do
        post diaper_drive_participants_path(default_params.merge(diaper_drive_participant: { name: "test" }, xhr: true))
        expect(response).to be_successful
        expect(response).to have_error(/try again/i)
      end
    end

    context "Looking at a different organization" do
      let(:object) { create(:diaper_drive_participant, organization: create(:organization)) }
      include_examples "requiring authorization"
    end
  end

  context "While not signed in" do
    let(:object) { create(:diaper_drive_participant) }

    include_examples "requiring authorization"
  end
end
