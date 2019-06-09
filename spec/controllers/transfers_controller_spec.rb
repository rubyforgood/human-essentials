RSpec.describe TransfersController, type: :controller do
  context "While signed in" do
    before do
      sign_in(@user)
    end

    describe "GET #index" do
      subject { get :index, params: { organization_id: @organization.short_name } }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "POST #create" do
      it "redirects to #show when successful" do
        attributes = attributes_for(
          :transfer,
          organization_id: @organization.id,
          to_id: create(:storage_location, organization: @organization).id,
          from_id: create(:storage_location, organization: @organization).id
        )

        post :create, params: { organization_id: @organization.short_name, transfer: attributes }
        expect(response).to redirect_to(transfers_path)
      end

      it "renders to #new when failing" do
        post :create, params: { organization_id: @organization.short_name, transfer: { from_id: nil, to_id: nil } }
        expect(response).to be_successful # Will render :new
        expect(response).to render_template("new")
        expect(response).to have_error(/error/i)
      end
    end

    describe "GET #new" do
      subject { get :new, params: { organization_id: @organization.short_name } }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "GET #show" do
      subject { get :show, params: { organization_id: @organization.short_name, id: create(:transfer, organization: @organization) } }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end
    context "Looking at a different organization" do
      let(:object) do
        org = create(:organization)
        create(:transfer,
               to: create(:storage_location, organization: org),
               from: create(:storage_location, organization: org),
               organization: org)
      end
      include_examples "requiring authorization", except: %i(edit update destroy)
    end
  end

  context "While not signed in" do
    let(:object) { create(:transfer) }

    include_examples "requiring authorization", except: %i(edit update destroy)
  end
end
