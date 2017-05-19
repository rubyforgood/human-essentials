RSpec.describe StorageLocationsController, type: :controller do
  describe "GET #index" do
    subject { get :index }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "GET #new" do
    subject { get :new }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "GET #edit" do
    subject { get :edit, params: { id: create(:storage_location) } }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "GET #show" do
    subject { get :show, params: { id: create(:storage_location) } }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "GET #destroy" do
    subject { delete :destroy, params: { id: create(:storage_location) } }
    it "redirects to #index" do
      expect(subject).to redirect_to(storage_locations_path)
    end
  end
end
