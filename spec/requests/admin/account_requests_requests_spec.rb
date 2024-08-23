RSpec.describe 'Admin::AccountRequestsController', type: :request do
  let(:organization) { create(:organization) }

  context 'while signed in as a super admin' do
    before do
      sign_in(create(:super_admin, organization: organization))
    end

    describe 'GET #index' do
      it 'returns success' do
        get admin_account_requests_path
        expect(response).to be_successful
      end
    end

    describe 'GET #for_rejection' do
      let(:account_request) { create(:account_request, organization_name: 'Test Org 1') }

      context 'with an invalid token' do
        it 'should show a not found message' do
          allow(AccountRequest).to receive(:get_by_identity_token).and_return(nil)
          get for_rejection_admin_account_requests_path(token: 'my token')
          expect(response.body).to match(/Account Request not found!/)
        end
      end

      context 'with a valid token' do
        it 'should show the request' do
          create(:account_request, organization_name: 'Test Org 2')
          allow(AccountRequest).to receive(:get_by_identity_token).and_return(account_request)
          get for_rejection_admin_account_requests_path(token: 'my token')
          expect(response.body).to match(/Test Org 1/)
          expect(response.body).not_to match(/Test Org 2/)
          expect(AccountRequest).to have_received(:get_by_identity_token).with('my token')
        end
      end
    end

    describe 'POST #reject' do
      let(:account_request) { FactoryBot.create(:account_request) }

      it 'should redirect back on success' do
        params = {
          account_request: {
            id: account_request.id,
            rejection_reason: "because I said so"
          }
        }
        redir = admin_account_requests_path
        post reject_admin_account_requests_path(params: params)
        expect(request.flash[:notice]).to eq("Account request rejected!")
        expect(response).to redirect_to(redir)
      end
    end
  end
end
