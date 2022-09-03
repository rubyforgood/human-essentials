RSpec.describe "BarcodeItems", type: :request do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  context "While signed in" do
    before do
      sign_in(@user)
    end

    describe "GET #index" do
      subject do
        get barcode_items_path(default_params.merge(format: response_format))
        response
      end

      before { create(:barcode_item) }

      context "html" do
        let(:response_format) { 'html' }

        it { is_expected.to be_successful }
      end

      context "csv" do
        let(:response_format) { 'csv' }

        it { is_expected.to be_successful }
      end
    end

    describe "GET #new" do
      it "returns http success" do
        get new_barcode_item_path(default_params)
        expect(response).to be_successful
      end
    end

    describe "GET #edit" do
      context "with a normal barcode item" do
        it "returns http success" do
          get edit_barcode_item_path(default_params.merge(id: create(:barcode_item)))
          expect(response).to be_successful
        end
      end

      context "with a global barcode item" do
        it "returns a 404" do
          get edit_barcode_item_path(default_params.merge(id: create(:global_barcode_item)))
          expect(response.status).to eq(404)
        end
      end
    end

    describe "GET #show" do
      context "with a normal barcode item" do
        it "returns http success" do
          get barcode_item_path(default_params.merge(id: create(:barcode_item)))
          expect(response).to be_successful
        end
      end

      context "with a global barcode item" do
        it "returns a 404" do
          get barcode_item_path(default_params.merge(id: create(:global_barcode_item)))
          expect(response.status).to eq(404)
        end
      end
    end

    describe "GET #find" do
      let!(:global_barcode) { create(:global_barcode_item) }
      let!(:organization_barcode) { create(:barcode_item, organization: @organization) }
      let!(:other_barcode) { create(:barcode_item, organization: create(:organization)) }

      context "via ajax" do
        it "can find a barcode that is scoped to just this organization" do
          get find_barcode_items_path(default_params.merge(barcode_item: { value: organization_barcode.value }, format: :json))
          expect(response).to be_successful
          result = JSON.parse(response.body)
          expect(result["barcode_item"]["barcodeable_type"]).to eq("Item")
          expect(result["barcode_item"]["id"].to_i).to eq(organization_barcode.id)
        end

        it "can find a barcode that's universally available" do
          get find_barcode_items_path(default_params.merge(barcode_item: { value: global_barcode.value }, format: :json))
          expect(response).to be_successful
          result = JSON.parse(response.body)
          expect(result["barcode_item"]["barcodeable_type"]).to eq("BaseItem")
          expect(result["barcode_item"]["id"].to_i).to eq(global_barcode.id)
        end

        context "when it's missing" do
          it "returns a 404" do
            get find_barcode_items_path(default_params.merge(barcode_item: { value: other_barcode.value }, format: :json))
            expect(response.status).to eq(404)
          end
        end
      end
    end

    describe "DELETE #destroy" do
      it "disallows a user to delete someone else's barcode" do
        other_org = create(:organization)
        other_barcode = create(:barcode_item, organization_id: other_org.id)
        delete barcode_item_path(default_params.merge(id: other_barcode.to_param))
        expect(response).not_to be_successful
        expect(response).to have_error(/permission/)
      end

      it "disallows a non-superadmin to delete a global barcode" do
        allow_any_instance_of(User).to receive(:super_admin?).and_return(false)
        global_barcode = create(:global_barcode_item)
        delete barcode_item_path(default_params.merge(id: global_barcode.to_param))
        expect(response).not_to be_successful
        expect(response).to have_error(/permission/)
      end

      it "redirects to the index" do
        delete barcode_item_path(default_params.merge(id: create(:barcode_item, organization_id: @organization.id)))
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
