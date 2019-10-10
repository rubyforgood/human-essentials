RSpec.describe Admin::PartnersController, type: :controller do
  context "When logged in as a super admin" do
    before do
      sign_in(@super_admin)
    end

    describe "GET #index" do
      it "returns http success" do
        get :index
        expect(response).to be_successful
      end
    end
  end
end
