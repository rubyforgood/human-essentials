RSpec.describe 'Admin::BarcodeItemsController', type: :request do
  let(:organization) { create(:organization) }

  context 'while signed in as a super admin' do
    before do
      sign_in(create(:super_admin, organization: organization))
    end

    describe 'GET #index' do
      it 'returns success' do
        get admin_barcode_items_path
        expect(response).to be_successful
      end

      # The filter select on this page rendered for years without the action ever calling
      # `class_filter`, so choosing a base item reloaded the same full list.
      context 'with a base item filter' do
        let!(:wanted) { create(:base_item, name: 'Wanted base item') }
        let!(:other) { create(:base_item, name: 'Other base item') }
        let!(:wanted_barcode) { create(:global_barcode_item, barcodeable: wanted, value: '111') }
        let!(:other_barcode) { create(:global_barcode_item, barcodeable: other, value: '222') }

        it 'shows every global barcode when nothing is chosen' do
          get admin_barcode_items_path
          expect(response.body).to include('111')
          expect(response.body).to include('222')
        end

        it 'narrows the list to the chosen base item' do
          get admin_barcode_items_path(filters: {barcodeable_id: wanted.id})
          expect(response.body).to include('111')
          expect(response.body).not_to include('222')
        end
      end
    end

    describe 'GET #new' do
      it 'returns success' do
        get new_admin_barcode_item_path
        expect(response).to be_successful
      end
    end

    describe 'POST #create' do
      let!(:base_item) { create(:base_item) }

      context 'with valid params' do
        let(:valid_params) do
          { barcode_item: { barcodeable_id: base_item.id, value: '1', quantity: 1 } }
        end

        it 'redirects to admin_barcode_items_path' do
          post admin_barcode_items_path, params: valid_params
          expect(response).to redirect_to(
            admin_barcode_items_path
          )
        end

        it 'creates a barcode item' do
          expect do
            post admin_barcode_items_path, params: valid_params
          end.to change(base_item.barcode_items, :count).by(1)
        end
      end

      context 'with invalid params' do
        let(:invalid_params) do
          { barcode_item: { value: '1', quantity: 1 } }
        end

        it 'returns a successful response (to show form with errors)' do
          post admin_barcode_items_path, params: invalid_params
          expect(response).to be_successful
        end
      end
    end

    describe 'PATCH #update' do
      let!(:barcode_item) { create(:global_barcode_item) }

      context 'with valid params' do
        let(:valid_params) do
          { barcode_item: { value: '123' } }
        end

        it 'redirects to admin_barcode_items_path' do
          patch admin_barcode_item_path(barcode_item), params: valid_params
          expect(response).to redirect_to(
            admin_barcode_items_path
          )
        end

        it 'updates the barcode_item attributes accordingly' do
          patch admin_barcode_item_path(barcode_item), params: valid_params
          expect(barcode_item.reload.value).to eq('123')
        end
      end

      context 'with invalid params' do
        let(:invalid_params) do
          { id: barcode_item.id, barcode_item: { quantity: 'Ranch it Up' } }
        end

        it 'returns a successful response (to show form with errors)' do
          put admin_barcode_item_path(barcode_item), params: invalid_params
          expect(response).to be_successful
        end
      end
    end

    describe 'DELETE #destroy' do
      it 'allows deletion of barcode in another org' do
        other_org = create(:organization)
        other_barcode = create(:barcode_item, organization_id: other_org.id)

        expect do
          delete admin_barcode_item_path(other_barcode)
        end.to change { BarcodeItem.count }.by(-1)
      end

      it 'allows deletion of a global barcode' do
        other_barcode = create(:global_barcode_item)

        expect do
          delete admin_barcode_item_path(other_barcode)
        end.to change { BarcodeItem.count }.by(-1)
      end
    end
  end
end
