RSpec.describe "/account_requests", type: :request do
  describe "GET #new" do
    it "renders a successful response" do
      get new_account_request_url
      expect(response).to be_successful
    end
  end

  describe 'GET #confirm' do
    context 'when given a valid token' do
      let!(:account_request) { FactoryBot.create(:account_request) }

      it 'should the update confirmed_at on the account_request, queue confirmation email and render confirm template' do
        expect(account_request.confirmed_at).to eq(nil)

        expect do
          get confirm_account_requests_url(token: account_request.identity_token)
        end.to have_enqueued_job.on_queue('default')

        expect(account_request.reload.confirmed_at).not_to eq(nil)
        expect(response).to render_template(:confirm)
      end
    end

    context 'when given a invalid token' do
      let(:fake_token) { 'not-a-real-token' }

      it 'should render a error that says that is code provided is invalid' do
        get confirm_account_requests_url(token: fake_token)

        expect(response).to redirect_to(invalid_token_account_requests_url(token: fake_token))
      end
    end

    context 'when given a token that has already been confirmed' do
      let!(:account_request) { FactoryBot.create(:account_request) }
      before do
        create(:organization, account_request_id: account_request.id)
      end

      it 'should render a error that says that is code provided is invalid' do
        get confirm_account_requests_url(token: account_request.identity_token)

        expect(response).to redirect_to(invalid_token_account_requests_url(token: account_request.identity_token))
      end
    end
  end

  describe 'GET #confirmation' do
    context 'when given a valid token' do
      let!(:account_request) { FactoryBot.create(:account_request) }

      it 'should render the confirmation template' do
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

    context 'when given a token that has already been confirmed' do
      let!(:account_request) { FactoryBot.create(:account_request) }
      before do
        FactoryBot.create(:organization, account_request_id: account_request.id)
      end

      it 'should render a error that says that is code provided is invalid' do
        get confirmation_account_requests_url(token: account_request.identity_token)

        expect(response).to redirect_to(invalid_token_account_requests_url(token: account_request.identity_token))
      end
    end
  end

  describe 'GET #received' do
    context 'when given a valid token' do
      let!(:account_request) { FactoryBot.create(:account_request) }

      it 'should render the received template' do
        get received_account_requests_url(token: account_request.identity_token)
        expect(response).to render_template(:received)
      end
    end

    context 'when given a invalid token' do
      let(:fake_token) { 'not-a-real-token' }

      it 'should render a error that says that is code provided is invalid' do
        get received_account_requests_url(token: fake_token)

        expect(response).to redirect_to(invalid_token_account_requests_url(token: fake_token))
      end
    end
  end

  describe "POST #create" do
    context "with valid parameters" do
      let(:valid_create_attributes) { FactoryBot.attributes_for(:account_request) }

      it "creates a new AccountRequest" do
        expect do
          post account_requests_url, params: { account_request: valid_create_attributes }
        end.to change(AccountRequest, :count).by(1)
      end

      it "redirects to the created account_request confirmation" do
        post account_requests_url, params: { account_request: valid_create_attributes }

        identity_token = AccountRequest.last.identity_token
        expect(response).to redirect_to(received_account_requests_url(token: identity_token))
      end

      it 'delivers the confirmation email via default queue' do
        expect do
          post account_requests_url, params: { account_request: valid_create_attributes }
        end.to have_enqueued_job.on_queue('default')
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) { { name: Faker::Name.name } }

      it "does not create a new AccountRequest" do
        expect do
          post account_requests_url, params: { account_request: invalid_attributes }
        end.to change(AccountRequest, :count).by(0)
      end

      it "renders a successful response (i.e. to display the 'new' template)" do
        post account_requests_url, params: { account_request: invalid_attributes }
        expect(response).to be_successful
      end
    end
  end
end
