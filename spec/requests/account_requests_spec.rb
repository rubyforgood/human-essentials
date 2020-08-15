require 'rails_helper'

RSpec.describe "/account_requests", type: :request do

  describe "GET #new" do
    it "renders a successful response" do
      get new_account_request_url
      expect(response).to be_successful
    end
  end

  describe 'GET #confirmation' do
    context 'when given a valid token' do
      let!(:account_request) { FactoryBot.create(:account_request) }

      it 'should the confirmation template' do
        get confirmation_account_requests_url(token: account_request.identity_token)
        expect(response).to render_template(:confirmation)
      end
    end

    context 'when given a invalid token' do
      let(:fake_token) { 'not-a-real-token' }

      it 'should render a error that says that is code provided is invalid' do
        get confirmation_account_requests_url(token: fake_token)

        expect(response).to redirect_to(invalid_token_account_requests_url(token: fake_token))
      end
    end
  end

  describe "POST #create" do
    context "with valid parameters" do
      let(:valid_create_attributes) { FactoryBot.attributes_for(:account_request) }

      it "creates a new AccountRequest" do
        expect {
          post account_requests_url, params: { account_request: valid_create_attributes }
        }.to change(AccountRequest, :count).by(1)
      end

      it "redirects to the created account_request confirmation" do
        post account_requests_url, params: { account_request: valid_create_attributes }

        identity_token = AccountRequest.last.identity_token
        expect(response).to redirect_to(confirmation_account_requests_url(token: identity_token))
      end

      it 'delivers the queue' do
        expect {
          post account_requests_url, params: { account_request: valid_create_attributes }
        }.to have_enqueued_job.on_queue('mailers')
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) { { } }

      it "does not create a new AccountRequest" do
        expect {
          post account_requests_url, params: { account_request: invalid_attributes }
        }.to change(AccountRequest, :count).by(0)
      end

      it "renders a successful response (i.e. to display the 'new' template)" do
        post account_requests_url, params: { account_request: invalid_attributes }
        expect(response).to be_successful
      end
    end
  end
end
