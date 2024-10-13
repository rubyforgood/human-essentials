RSpec.describe 'Requests', type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  context 'When signed' do
    before { sign_in(user) }

    describe "GET #index" do
      subject do
        get requests_path(format: response_format)
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

      context "when there are pending or started requests" do
        it "shows print unfulfilled picklists button with correct quantity" do
          Request.delete_all

          create(:request, :pending)
          create(:request, :started)
          create(:request, :fulfilled)
          create(:request, :discarded)

          get requests_path

          expect(response.body).to include('Print Unfulfilled Picklists (2)')
        end
      end
    end

    describe 'GET #show' do
      context 'When the request exists' do
        let(:request) { create(:request, organization: organization) }

        it 'responds with success' do
          get request_path(request)

          expect(response).to have_http_status(:ok)
        end
      end

      context 'When the request does not exist' do
        it 'responds with not found' do
          get request_path(id: 1)

          expect(response).to have_http_status(:not_found)
        end
      end

      context 'When organization has a default storage location' do
        let(:request) { create(:request, organization: create(:organization, default_storage_location: 1)) }
        it 'shows the column Default storage location inventory' do
          get request_path(request)

          expect(response.body).to include('Default storage location inventory')
        end
      end

      context 'When partner has a default storage location' do
        let(:storage_location) { create(:storage_location) }
        let(:request) { create(:request, partner: create(:partner, default_storage_location_id: storage_location.id)) }
        it 'shows the column Default storage location inventory' do
          get request_path(request)

          expect(response.body).to include('Default storage location inventory')
        end
      end

      context 'When neither partner nor organization has a default storage location' do
        let(:request) { create(:request, organization: organization) }
        it 'does not show the column Default storage location inventory' do
          get request_path(request)

          expect(response.body).not_to include('Default storage location inventory')
        end
      end

      context 'When packs are enabled' do
        before { Flipper.enable(:enable_packs) }
        let(:item) { create(:item, name: "Item", organization: organization) }
        let(:request) { create(:request, organization: organization) }

        it 'shows a units column and custom unit if any item has custom units' do
          create(:item_unit, item: item, name: "Pack")
          create(:item_request, request: request, request_unit: "Pack", item: item)

          get request_path(request)

          expect(response.body).to include('Units (if applicable)')
          expect(response.body).to include('<td>Packs</td>')
        end

        it 'does not show a units column or any unit if no items have custom units' do
          create(:item_unit, item: item, name: "Pack")
          create(:item_request, request: request, request_unit: nil, item: item)

          get request_path(request)

          expect(response.body).to_not include('Units (if applicable)')
          expect(response.body).to_not include('<td>Packs</td>')
        end
      end

      context 'When packs are not enabled' do
        let(:request) { create(:request, organization: organization) }

        it 'does not show a units column' do
          get request_path(request)

          expect(response.body).not_to include('Units (if applicable)')
        end
      end
    end

    describe 'POST #start' do
      context 'When request exists' do
        let(:request) { create(:request, organization: organization) }

        it 'changes the request status from pending to started' do
          expect do
            post start_request_path(request)
            request.reload
          end.to change(request, :status).from('pending').to('started')
        end

        it 'redirects to new_distribution_path and flashes a notice', :aggregate_failures do
          post start_request_path(request)

          expect(flash[:notice]).to eq('Request started')
          expect(response).to redirect_to(new_distribution_path(request_id: request.id))
        end
      end

      context 'When the request does not exist' do
        it 'responds with not found' do
          post start_request_path(1)

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
