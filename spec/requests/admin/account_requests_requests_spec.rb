require 'rails_helper'

RSpec.describe 'Admin::AccountRequestsController', type: :request do
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
  end
end
