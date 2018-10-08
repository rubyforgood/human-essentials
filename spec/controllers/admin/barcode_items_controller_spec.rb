RSpec.describe Admin::BarcodeItemsController, type: :controller do
  context "while signed in as a super admin" do
    before do
      sign_in(@super_admin)
    end

    describe "DELETE #destroy" do
      it "can delete anyone's barcode" do
        allow_any_instance_of(User).to receive(:super_admin?).and_return(true)
        other_org = create(:organization)
        other_barcode = create(:barcode_item, organization_id: other_org.id, global: false)
        expect do
          delete :destroy, params: { id: other_barcode.to_param }
        end.to change { BarcodeItem.count }.by(-1)
        expect(flash.to_h).not_to have_key("error")
      end

      it "allows deletion of a global barcode" do
        allow_any_instance_of(User).to receive(:super_admin?).and_return(true)
        other_barcode = create(:barcode_item, global: true)
        expect do
          delete :destroy, params: { id: other_barcode.to_param }
        end.to change { BarcodeItem.count }.by(-1)
        expect(flash.to_h).not_to have_key("error")
      end
    end
  end
end