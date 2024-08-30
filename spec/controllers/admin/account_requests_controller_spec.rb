RSpec.describe Admin::AccountRequestsController, type: :controller do
  before do
    sign_in(create(:super_admin, organization: nil))
  end

  let(:account_request) { create(:account_request) }
  let(:rejection_params) do
    {
      account_request: {
        id: account_request.id,
        rejection_reason: "some rejection reason"
      }
    }
  end

  describe "POST #reject" do
    it "should reject the account request" do
      post :reject, params: rejection_params
      expect(account_request.reload).to be_rejected
      expect(flash[:notice]).to eq("Account request rejected!")
      expect(response).to redirect_to(admin_account_requests_path)
    end
  end

  describe "POST #close" do
    it "should close the account request" do
      post :close, params: rejection_params
      expect(account_request.reload).to be_admin_closed
      expect(flash[:notice]).to eq("Account request closed!")
      expect(response).to redirect_to(admin_account_requests_path)
    end
  end
end
