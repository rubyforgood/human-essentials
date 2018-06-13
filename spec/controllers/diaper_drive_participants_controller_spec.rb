RSpec.describe DiaperDriveParticipantsController, type: :controller do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  context "While signed in" do
    before do
      sign_in(@user)
    end

    describe "GET #index" do
      subject { get :index, params: default_params }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "GET #new" do
      subject { get :new, params: default_params }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "GET #edit" do
      subject { get :edit, params: default_params.merge(id: create(:diaper_drive_participant, organization: @user.organization)) }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "GET #show" do
      subject { get :show, params: default_params.merge(id: create(:diaper_drive_participant, organization: @organization)) }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "DELETE #destroy" do
      subject { delete :destroy, params: default_params.merge(id: create(:diaper_drive_participant)) }
      it "does not have a route for this" do
        expect { subject }.to raise_error(ActionController::UrlGenerationError)
      end
    end

    describe "XHR #create" do
      it "successful create" do
        post :create, xhr: true, params: default_params.merge(diaper_drive_participant: { name: "test", email: "123@mail.ru" })
        expect(response).to be_successful
      end

      it "flash error" do
        post :create, xhr: true, params: default_params.merge(diaper_drive_participant: { name: "test" })
        expect(response).to be_successful
        expect(flash[:error]).to match(/try again/i)
      end
    end

    describe "POST #create" do
      it "successful create" do
        post :create, params: default_params.merge(diaper_drive_participant: { name: "test", email: "123@mail.ru" })
        expect(response).to redirect_to(diaper_drive_participants_path)
        expect(flash[:notice]).to match(/added!/i)
      end

      it "flash error" do
        post :create, xhr: true, params: default_params.merge(diaper_drive_participant: { name: "test" })
        expect(response).to be_successful
        expect(flash[:error]).to match(/try again/i)
      end
    end

    context "Looking at a different organization" do
      let(:object) { create(:diaper_drive_participant, organization: create(:organization)) }
      include_examples "requiring authorization"
    end
  end

  context "While not signed in" do
    let(:object) { create(:diaper_drive_participant) }

    include_examples "requiring authentication"
  end
end
