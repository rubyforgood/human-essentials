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
          create(:request, :cancelled)

          get requests_path

          expect(response.body).to include('Print Unfulfilled Picklists (2)')
          expect(response.body).not_to match(%r{<span class="badge badge-danger bg-danger">\s*Cancelled\s*</span>})
        end
      end

      context "when 'include_cancelled' param is present" do
        it "shows print unfulfilled picklists button with correct quantity including cancelled requests" do
          Request.delete_all

          create(:request, :pending)
          create(:request, :started)
          create(:request, :cancelled)

          get requests_path, params: {include_cancelled: "1"}

          expect(response.body).to include('Print Unfulfilled Picklists (2)')
          expect(response.body).to match(%r{<span class="badge badge-danger bg-danger">\s*Cancelled\s*</span>})
        end
      end

      context "when 'Include Cancelled?' is checked and filter by Cancelled" do
        it "constrains the list for cancelled requests only" do
          Request.delete_all

          create(:request, :started, comments: "Need more supplies")
          create(:request, :pending, comments: "Awaiting for confirmation")
          create(:request, :cancelled, comments: 'Not necessary anymore')

          get requests_path, params: {include_cancelled: "1", filters: { by_status: :cancelled}}

          expect(response.body).to include("Not necessary anymore")
          expect(response.body).not_to include("Need more supplies")
          expect(response.body).not_to include("Awaiting for confirmation")
        end
      end

      context "when there is a filter applied" do
        it "shows only filtered requests, print unfulfilled picklists button with correct quantity" do
          Request.delete_all

          create(:request, :started, comments: "Started request - should appear")
          create(:request, :pending, comments: "Pending request - should not appear")
          create(:request, :cancelled, comments: 'Cancelled request - a comment')

          get requests_path({ filters: { by_status: :started} })

          expect(response.body).to include("Print Unfulfilled Picklists (1)")
          expect(response.body).to include("Started request - should appear")
          expect(response.body).not_to include("Pending request - should not appear")
          expect(response.body).not_to include("Cancelled request - a comment")
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

      context 'When the request belongs to another organization' do
        let(:other_organization) { create(:organization) }
        let(:other_request) { create(:request, organization: other_organization) }

        it 'responds with not found' do
          get request_path(other_request)

          expect(response).to have_http_status(:not_found)
        end
      end

      context 'When organization has a default storage location' do
        let(:storage_location) { create(:storage_location, organization: organization) }
        let(:request) do
          organization.update!(default_storage_location: storage_location.id)
          create(:request, organization: organization)
        end

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

      context 'When the request belongs to another organization' do
        let(:other_organization) { create(:organization) }
        let(:other_request) { create(:request, organization: other_organization) }

        it 'responds with not found and does not change status' do
          expect do
            post start_request_path(other_request)
          end.not_to change { other_request.reload.status }

          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
