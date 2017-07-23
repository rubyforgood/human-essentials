RSpec.describe BarcodeItemsController, type: :controller do
  let(:default_params) {
    { organization_id: @organization.to_param }
  }

  context "While signed in" do
    before do
      sign_in(@user)
    end

    describe "GET #index" do
      subject { get :index, params: default_params }
      it "returns http success" do
        expect(subject).to have_http_status(:success)
      end
    end

    describe "GET #new" do
      subject { get :new, params: default_params }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "GET #edit" do
      subject { get :edit, params: default_params.merge({ id: create(:barcode_item) }) }
      it "returns http success" do
        expect(subject).to have_http_status(:success)
      end
    end

    describe "GET #show" do
      subject { get :show, params: default_params.merge({ id: create(:barcode_item) }) }
      it "returns http success" do
        expect(subject).to be_successful
      end

      context "via ajax" do
        context "when the object exists" do
          subject { get :show, params: default_params.merge({ id: create(:barcode_item), format: :json}) }
          it "returns http success" do
            expect(subject).to be_successful
          end
        end

        context "when it's missing" do
          it "returns a 404" do
            get :show, params: default_params.merge({ id: 9999999, format: :json })
            expect(response.status).to eq(404)
          end
        end
      end

    end

    describe "DELETE #destroy" do
      subject { delete :destroy, params: default_params.merge({ id: create(:barcode_item) }) }
      it "redirecst to the index" do
        expect(subject).to redirect_to(barcode_items_path)
      end
    end

    context "Looking at a different organization" do
      let(:object) { create(:barcode_item, organization: create(:organization) ) }
      include_examples "requiring authorization"
    end
  end

  context "While not signed in" do
    let(:object) { create(:barcode_item) }

    include_examples "requiring authentication"
  end

end
