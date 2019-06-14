RSpec.describe Admin::BarcodeItemsController, type: :controller do
  context 'while signed in as a super admin' do
    before do
      sign_in(@super_admin)
    end

    describe 'GET #index' do
      let!(:item) { create(:base_item) }
      let!(:barcode_item) { create(:global_barcode_item) }

      before do
        get :index
      end

      it 'returns success' do
        expect(response).to be_successful
      end

      it 'assigns @items' do
        expect(assigns[:items]).to include(item)
      end

      it 'assigns @barcode_items' do
        expect(assigns[:barcode_items]).to include(barcode_item)
      end
    end

    describe 'GET #new' do
      before do
        get :new
      end

      it 'renders :new' do
        expect(response).to render_template(:new)
      end

      it 'builds a barcode_item' do
        expect(assigns(:barcode_item)).to be_a_new(BarcodeItem)
      end
    end

    describe 'POST #create' do
      let!(:base_item) { create(:base_item) }

      context 'success' do
        it 'redirects to admin_barcode_items_path when created successfully' do
          post :create, params: { barcode_item: { barcodeable_id: base_item.id, value: '1', quantity: 1 } }

          expect(response).to redirect_to(admin_barcode_items_path)
        end
      end

      context 'failure' do
        before do
          post :create, params: { barcode_item: { value: '1', quantity: 1 } }
        end

        it "notifies if the barcode isn't created successfully" do
          expect(flash[:error]).to match('Failed to create Barcode Item.')
        end

        it 'renders new' do
          expect(response).to render_template(:new)
        end
      end
    end

    describe 'PATCH #update' do
      let!(:barcode_item) { create(:global_barcode_item) }

      context 'sucess' do
        before do
          put :update, params: { id: barcode_item.id, barcode_item: { value: '123' } }
        end

        it 'redirects to admin_barcode_items_path' do
          expect(response).to redirect_to(admin_barcode_items_path)
        end

        it 'updates the barcode_item attributes accordingly' do
          expect(barcode_item.reload.value).to eq('123')
        end
      end

      context 'failure' do
        it 'render edit and notifies the user' do
          put :update, params: { id: barcode_item.id, barcode_item: { quantity: 'Ranch it Up' } }

          expect(response).to render_template(:edit)
          expect(flash[:error]).to match('Failed to update this Barcode Item.')
        end
      end
    end

    describe 'DELETE #destroy' do
      it "can delete anyone's barcode" do
        allow_any_instance_of(User).to receive(:super_admin?).and_return(true)
        other_org = create(:organization)
        other_barcode = create(:barcode_item, organization_id: other_org.id, global: false)
        expect do
          delete :destroy, params: { id: other_barcode.to_param }
        end.to change { BarcodeItem.count }.by(-1)
        expect(response).not_to have_error
      end

      it 'allows deletion of a global barcode' do
        allow_any_instance_of(User).to receive(:super_admin?).and_return(true)
        other_barcode = create(:barcode_item, global: true)
        expect do
          delete :destroy, params: { id: other_barcode.to_param }
        end.to change { BarcodeItem.count }.by(-1)
        expect(response).not_to have_error
      end
    end
  end
end
