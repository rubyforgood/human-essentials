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

    describe "POST #import_csv" do
      context "with a csv file" do
        let(:file) { Rack::Test::UploadedFile.new "spec/fixtures/diaper_drive_participants.csv", "text/csv" }
        subject { post :import_csv, params: default_params.merge(file: file) }

        it "invokes DiaperDriveParticipant.import_csv" do
          expect(DiaperDriveParticipant).to respond_to(:import_csv).with(2).arguments
        end

        it "redirects to :index" do
          expect(subject).to redirect_to(diaper_drive_participants_path(organization_id: @organization))
        end

        it "presents a flash notice message" do
          expect(subject.request.flash[:notice]).to eq "Diaper drive participants were imported successfully!"
        end
      end

      context "without a csv file" do
        subject { post :import_csv, params: default_params }

        it "redirects to :index" do
          expect(subject).to redirect_to(diaper_drive_participants_path(organization_id: @organization))
        end

        it "presents a flash error message" do
          expect(subject.request.flash[:error]).to eq "No file was attached!"
        end
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
        post :create, params: default_params.merge(diaper_drive_participant: { business_name: "businesstest",
                                                                               contact_name: "test", email: "123@mail.ru" })
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

    include_examples "requiring authorization"
  end
end
