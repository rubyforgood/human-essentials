

RSpec.describe BarcodeItemsController, type: :controller do
  before do
    sign_in(@user)
  end

  describe "GET #index" do
    subject { get :index, params: { organization_id: @organization.short_name } }
    it "returns http success" do
      expect(subject).to have_http_status(:success)
    end
  end

  describe "GET #new" do
    subject { get :new, params: { organization_id: @organization.short_name } }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "GET #edit" do
    subject { get :edit, params: { id: create(:barcode_item), organization_id: @organization.short_name } }
    it "returns http success" do
      expect(subject).to have_http_status(:success)
    end
  end

  describe "GET #show" do
    subject { get :show, params: { id: create(:barcode_item), organization_id: @organization.short_name } }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "DELETE #destroy" do
    subject { delete :destroy, params: { id: create(:barcode_item), organization_id: @organization.short_name } }
    it "redirecst to the index" do
      expect(subject).to redirect_to(barcode_items_path)
    end
  end

end
