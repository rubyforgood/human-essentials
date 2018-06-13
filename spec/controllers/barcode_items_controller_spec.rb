RSpec.describe BarcodeItemsController, type: :controller do
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
      subject { get :edit, params: default_params.merge(id: create(:barcode_item, global: true)) }
      it "returns http success" do
        expect(subject).to have_http_status(:success)
      end
    end

    describe "GET #show" do
      subject { get :show, params: default_params.merge(id: create(:barcode_item, global: true)) }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "GET #find" do
      let!(:global_barcode) { create(:barcode_item, global: true) }
      let!(:organization_barcode) { create(:barcode_item, organization: @organization) }
      let!(:other_barcode) { create(:barcode_item, organization: create(:organization)) }
      context "via ajax" do
        subject { get :find, params: default_params.merge(barcode_item: { value: organization_barcode.value }, format: :json) }
        it "can find a barcode that is scoped to just this organization" do
          expect(subject).to be_successful
        end

        it "can find a barcode that's universally available" do
          get :find, params: default_params.merge(barcode_item: { value: global_barcode.value }, format: :json)
          expect(response).to be_successful
        end

        context "when it's missing" do
          it "returns a 404" do
            get :find, params: default_params.merge(barcode_item: { value: other_barcode.value }, format: :json)
            expect(response.status).to eq(404)
          end
        end
      end
    end

    describe "DELETE #destroy" do
      it "disallows a user to delete someone else's barcode" do
        other_org = create(:organization)
        other_barcode = create(:barcode_item, organization_id: other_org.id, global: false)
        delete :destroy, params: default_params.merge(id: other_barcode.to_param)
        expect(response).not_to be_successful
        expect(flash[:error]).to match(/permission/)
      end

      it "disallows a non-superadmin to delete a global barcode" do
        allow_any_instance_of(User).to receive(:is_superadmin?).and_return(false)
        global_barcode = create(:global_barcode_item)
        delete :destroy, params: default_params.merge(id: global_barcode.to_param)
        expect(response).not_to be_successful
        expect(flash[:error]).to match(/permission/)
      end

      it "allows a superadmin to delete anyone's barcode" do
        allow_any_instance_of(User).to receive(:is_superadmin?).and_return(true)
        other_org = create(:organization)
        other_barcode = create(:barcode_item, organization_id: other_org.id, global: false)
        expect do
          delete :destroy, params: default_params.merge(id: other_barcode.to_param)
        end.to change { BarcodeItem.count }.by(-1)
        expect(flash.to_h).not_to have_key("error")
      end

      it "redirects to the index" do
        delete :destroy, params: default_params.merge(id: create(:barcode_item, global: false, organization_id: @organization.id))
        expect(subject).to redirect_to(barcode_items_path)
      end
    end

    context "Looking at a different organization" do
      let(:object) { create(:barcode_item, organization: create(:organization)) }
      include_examples "requiring authorization"
    end
  end

  # For the time being, users cannot access these routes, but this may change in
  # the near future.
  # context "While not signed in" do
  #  let(:object) { create(:barcode_item) }
  #  include_examples "requiring authentication"
  # end
end
