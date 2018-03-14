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
      subject { get :edit, params: default_params.merge(id: create(:diaper_drive_participant)) }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "GET #show" do
      subject { get :show, params: default_params.merge(id: create(:diaper_drive_participant)) }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "DELETE #destroy" do
      subject do
        delete :destroy,
               params: default_params.merge(id: create(:diaper_drive_participant))
      end
      it "does not have a route for this" do
        expect { subject }.to raise_error(ActionController::UrlGenerationError)
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
