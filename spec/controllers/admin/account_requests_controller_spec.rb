RSpec.describe Admin::AccountRequestsController, type: :controller do
  before do
    sign_in(create(:super_admin, organization: nil))
  end

  let(:account_request) { create(:account_request, status: :admin_approved) }

  describe "POST #close" do
    it "should not close the account request if it is invalid" do
      post :close, params: {account_request: {id: account_request.id}}
      expect(flash[:alert]).to eq("Cannot be closed from this state")
      expect(response).to redirect_to(admin_account_requests_path)
    end
  end
end
