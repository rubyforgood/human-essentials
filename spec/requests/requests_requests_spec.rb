require 'rails_helper'

RSpec.describe 'Requests', type: :request do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  context 'When signed' do
    before { sign_in(@user) }

    describe "GET #index" do
      subject do
        get requests_path(default_params.merge(format: response_format))
        response
      end

      before do
        create(:request)
      end

      context "html" do
        let(:response_format) { 'html' }

        it { is_expected.to be_successful }
      end

      context "csv" do
        let(:response_format) { 'csv' }

        it { is_expected.to be_successful }
      end
    end

    describe 'GET #show' do
      context 'When the request exists' do
        let(:request) { create(:request, organization: @organization) }

        it 'responds with success' do
          get request_path(request, default_params)

          expect(response).to have_http_status(:ok)
        end
      end

      context 'When the request does not exist' do
        it 'responds with not found' do
          get request_path(1, default_params)

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe 'DELETE #destroy' do
      context 'When the request exists' do
        let(:request) { create(:request, organization: @organization) }

        it 'redirects to requests index' do
          delete request_path(request, default_params)

          expect(response).to redirect_to(requests_path)
        end
      end

      context 'When the request does not exist' do
        it 'responds with not found' do
          delete request_path(1, default_params)

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe 'POST #start' do
      context 'When request exists' do
        let(:request) { create(:request, organization: @organization) }

        it 'changes the request status from pending to started' do
          expect do
            post start_request_path(request, default_params)
            request.reload
          end.to change(request, :status).from('pending').to('started')
        end

        it 'redirects to new_distribution_path and flashes a notice', :aggregate_failures do
          post start_request_path(request, default_params)

          expect(flash[:notice]).to eq('Request started')
          expect(response).to redirect_to(new_distribution_path(request_id: request.id))
        end
      end

      context 'When the request does not exist' do
        it 'responds with not found' do
          post start_request_path(@organization.id, 1)

          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  context 'When not signed' do
    let(:object) { create(:request) }

    include_examples 'requiring authorization'
  end
end
