require 'rails_helper'

RSpec.describe "/account_requests", type: :request do

  describe "GET #new" do
    it "renders a successful response" do
      get new_account_request_url
      expect(response).to be_successful
    end
  end

  describe 'GET #show' do
    context 'when a invalid code query parameter' do
      it 'should render a error that says that is code provided is invalid' do
      end
    end

    context 'when no code query paramter is provided' do
      it 'should render a error that says that the code provided is invalid' do

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

      it "redirects to the created account_request" do
        post account_requests_url, params: { account_request: valid_create_attributes }
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
