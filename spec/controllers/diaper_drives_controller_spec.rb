RSpec.describe DiaperDrivesController, type: :controller do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  context "While signed in >" do
    let(:diaper_drive) { create(:diaper_drive) }
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

    describe "POST#create" do
      let!(:storage_location) { create(:storage_location) }
      let!(:diaper_drive_site) { create(:diaper_drive_site) }
      let(:line_items) { [attributes_for(:line_item)] }
    end

    describe "PUT#update" do
      it "redirects to index after update" do
        # diaper_drive = create(:diaper_drive)
        # put :update, params: default_params.merge(id: diaper_drive.id, name: 'updated name')
        # expect(response).to redirect_to(diaper_drives_path)
      end
    end

    describe "GET #edit" do
      subject { get :edit, params: default_params.merge(id: diaper_drive.id) }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "GET #show" do
      subject { get :show, params: default_params.merge(id: diaper_drive.id) }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "DELETE #destroy" do
      subject { delete :destroy, params: default_params.merge(id: diaper_drive.id) }
      it "redirects to the index" do
        expect(subject).to redirect_to(diaper_drives_path)
      end
    end
  end
end