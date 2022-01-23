require 'rails_helper'

RSpec.describe 'Admin::AccountRequestsController', type: :request, skip_seed: true do
  context 'while signed in as a super admin' do
    before do
      sign_in(@super_admin)
    end

    describe 'GET #index' do
      it 'returns success' do
        get admin_account_requests_path
        expect(response).to be_successful
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
        referer = admin_account_requests_path(organization_id: @organization.to_param)
        post reject_admin_account_requests_path(params: params, headers: {'HTTP_REFERER' => referer})
        expect(request.flash[:notice]).to eq("Account request rejected!")
        expect(response).to redirect_to(referer)
      end
    end
  end
end
