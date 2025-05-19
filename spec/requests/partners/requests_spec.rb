RSpec.describe "/partners/requests", type: :request do
  let(:organization) { create(:organization) }
  let(:partner) { create(:partner, organization: organization) }
  let(:partner_user) { partner.primary_user }

  describe "GET #index" do
    subject { -> { get partners_requests_path } }
    let(:item1) { create(:item, name: "First item") }
    let(:item2) { create(:item, name: "Second item") }

    before do
      sign_in(partner_user)
    end

    it 'should render without any issues' do
      subject.call
      expect(response).to render_template(:index)
    end

    it 'should display total count of items in partner request' do
      create(
        :request,
        partner_id: partner.id,
        partner_user_id: partner_user.id,
        request_items: [
          {item_id: item1.id, quantity: '125'},
          {item_id: item2.id, quantity: '559'}
        ]
      )
      subject.call
      expect(response.body).to include("684")
    end

    it "displays comment and sender" do
      request = create(:request, partner_id: partner.id, request_items: [{item_id: item1.id, quantity: '125'}])
      subject.call
      expect(response.body).to include(request.comments)
      expect(response.body).to include(request.requester.email)
    end
  end

  describe "GET #new" do
    subject { get new_partners_request_path }

    before do
      sign_in(partner_user)
    end

    it 'should render without any issues' do
      subject
      expect(response).to render_template(:new)
    end

    context "when packs are enabled but there are no requestable items" do
      before do
        allow_any_instance_of(PartnerFetchRequestableItemsService).to receive(:call).and_return({})
        Flipper.enable(:enable_packs)
      end

      after do
        Flipper.disable(:enable_packs)
      end

      it 'should render without any issues' do
        subject
        expect(response).to render_template(:new)
      end
    end

    context "when first reaching the new page" do
      let(:requestable_items) { [["Item 1", 1], ["Item 2", 2], ["Item 3", 3]] }
      before do
        allow_any_instance_of(PartnerFetchRequestableItemsService).to receive(:call).and_return(requestable_items)
      end

      it "has the correct input fields" do
        subject

        expect(response.body).to include('<option value="">Select an item</option>')
        requestable_items.each do |item, index|
          expect(response.body).to include("<option value=\"#{index}\">#{item}</option>")
        end
      end
    end

    context "when signed in as an organization admin" do
      before { sign_in(org_admin) }
      subject { get new_partners_request_path(partner_id:) }

      context "when corresponding partner belongs to the organization" do
        let(:org_admin) { create(:organization_admin, organization:) }

        context "when param partner_id is present" do
          let(:partner_id) { partner.id }

          it "should render without any issues" do
            subject
            expect(response).to render_template(:new)
          end
        end

        context "when param partner_id is missing" do
          let(:partner_id) { "" }

          it "redirects to dashboard path and flashes an error" do
            subject
            expect(flash[:error]).to eq("That screen is not available. Please try again as a partner.")
            expect(response).to redirect_to(dashboard_path)
          end
        end
      end

      context "when corresponding partner doesn't belong to the organization" do
        let(:new_organization) { create(:organization) }
        let(:org_admin) { create(:organization_admin, organization: new_organization) }
        let(:partner_id) { partner.id }

        it "redirects to dashboard path and flashes an error" do
          subject
          expect(flash[:error]).to eq("That screen is not available. Please try again as a partner.")
          expect(response).to redirect_to(dashboard_path)
        end
      end
    end

    context "when signed in as an organization user" do
      let(:org_user) { create(:user) }
      before { sign_in(org_user) }

      it "redirects to dashboard path and flashes an error" do
        subject
        expect(flash[:error]).to eq("That screen is not available. Please try again as a partner.")
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end

  describe "GET #show" do
    let(:partner_user) { partner.primary_user }
    let(:partner) { create(:partner) }
    let!(:request) { create(:request, partner: partner) }

    before do
      sign_in(partner_user)
    end

    it 'should render without any issues' do
      get partners_request_path(request)
      expect(response.body).to include(request.id.to_s)
    end

    it 'should give a 404 error if not found' do
      id = Request.last.id + 1
      get partners_request_path(id)
      expect(response.code).to eq("404")
    end

    it 'should give a 404 error if forbidden' do
      other_partner = FactoryBot.create(:partner)
      other_request = FactoryBot.create(:request, partner: other_partner)
      get partners_request_path(other_request)
      expect(response.code).to eq("404")
    end

    it 'should show the units if they are provided and enabled' do
      item1 = create(:item, name: "First item")
      item2 = create(:item, name: "Second item")
      item3 = create(:item, name: "Third item")
      create(:item_unit, item: item1, name: "flat")
      create(:item_unit, item: item2, name: "flat")
      create(:item_unit, item: item3, name: "flat")
      request = create(
        :request,
        :with_item_requests,
        partner_id: partner.id,
        partner_user_id: partner_user.id,
        request_items: [
          {item_id: item1.id, quantity: '125'},
          {item_id: item2.id, quantity: '559', request_unit: 'flat'},
          {item_id: item3.id, quantity: '1', request_unit: 'flat'}
        ]
      )

      Flipper.enable(:enable_packs)
      get partners_request_path(request)
      expect(response.body).to match(/First item - 125/m)
      expect(response.body).to match(/Second item - 559\s+flats/m)
      expect(response.body).to match(/Third item - 1\s+flat/m)

      Flipper.disable(:enable_packs)
      get partners_request_path(request)
      expect(response.body).to match(/First item - 125/m)
      expect(response.body).to match(/Second item - 559/m)
      expect(response.body).to match(/Third item - 1/m)
    end
  end

  describe "POST #create" do
    subject { post partners_requests_path, params: request_attributes }
    let(:item1) { create(:item, name: "First item", organization: organization) }
    let(:item2) { create(:item, name: "Second item", organization: organization) }

    let(:request_attributes) do
      {
        request: {
          comments: Faker::Lorem.paragraph,
          item_requests_attributes: {
            "0" => {
              item_id: item1.id,
              request_unit: 'pack',
              quantity: Faker::Number.within(range: 4..13)
            }
          }
        }
      }
    end

    before do
      sign_in(partner_user)

      # Set up a variety of units that these two items are allowed to have
      FactoryBot.create(:unit, organization: organization, name: 'pack')
      FactoryBot.create(:unit, organization: organization, name: 'box')
      FactoryBot.create(:unit, organization: organization, name: 'notallowed')
      FactoryBot.create(:item_unit, item: item1, name: 'pack')
      FactoryBot.create(:item_unit, item: item1, name: 'box')
      FactoryBot.create(:item_unit, item: item2, name: 'pack')
      FactoryBot.create(:item_unit, item: item2, name: 'box')
    end

    context 'when given valid parameters' do
      it 'should redirect to the show page' do
        expect { subject }.to change { Request.count }.by(1)
        expect(response).to redirect_to(partners_request_path(Request.last.id))
        expect(response.request.flash[:success]).to eql "Request was successfully created."
      end
    end

    context 'when given invalid parameters' do
      it 'should not redirect' do
        request_attributes[:request][:item_requests_attributes]["0"][:quantity] = -8
        expect { post partners_requests_path, params: request_attributes }.to_not change { Request.count }

        expect(response).to be_unprocessable
        expect(response.body).to include("Oops! Something went wrong with your Request")
        expect(response.body).to include("Ensure each line item has a item selected AND a quantity greater than 0.")
        expect(response.body).to include("Still need help? Please contact your essentials bank, #{partner.organization.name}")
        expect(response.body).to include("Our email on record for them is:")
        expect(response.body).to include(partner.organization.email)
      end
    end

    context "after invalid submission" do
      let(:requestable_items) { [["Item 1", 1], ["Item 2", 2], ["Item 3", 3]] }
      before do
        allow_any_instance_of(PartnerFetchRequestableItemsService).to receive(:call).and_return(requestable_items)
      end

      it "has the correct input fields" do
        request_attributes[:request][:item_requests_attributes]["0"][:quantity] = -8
        post partners_requests_path, params: request_attributes

        expect(response.body).to include('<option value="">Select an item</option>')
        requestable_items.each do |item, index|
          expect(response.body).to include("<option value=\"#{index}\">#{item}</option>")
        end
      end
    end

    context "when there are mixed units" do
      context "on different items" do
        let(:request_attributes) do
          {
            request: {
              comments: Faker::Lorem.paragraph,
              item_requests_attributes: {
                "0" => {
                  item_id: item1.id,
                  request_unit: 'pack',
                  quantity: 12
                },
                "1" => {
                  item_id: item2.id,
                  request_unit: 'box',
                  quantity: 17
                }
              }
            }
          }
        end

        it "creates without error" do
          Flipper.enable(:enable_packs)
          expect { subject }.to change { Request.count }.by(1)
          expect(response).to redirect_to(partners_request_path(Request.last.id))
          expect(response.request.flash[:success]).to eql "Request was successfully created."
        end
      end

      context "on the same item" do
        let(:request_attributes) do
          {
            request: {
              comments: Faker::Lorem.paragraph,
              item_requests_attributes: {
                "0" => {
                  item_id: item1.id,
                  request_unit: 'pack',
                  quantity: 12
                },
                "1" => {
                  item_id: item1.id,
                  request_unit: 'box',
                  quantity: 17
                }
              }
            }
          }
        end

        it "results in an error" do
          Flipper.enable(:enable_packs)
          expect { post partners_requests_path, params: request_attributes }.to_not change { Request.count }
          expect(response).to be_unprocessable
          expect(response.body).to include("Please ensure a single unit is selected for each item")
        end
      end
    end

    context "when a request empty" do
      let(:request_attributes) do
        {
          request: {
            comments: "",
            item_requests_attributes: {
              "0" => {
                item_id: nil,
                quantity: nil
              }
            }
          }
        }
      end

      it "is invalid" do
        expect { post partners_requests_path, params: request_attributes }.to_not change { Request.count }

        expect(response).to be_unprocessable
        expect(response.body).to include("Oops! Something went wrong with your Request")
        expect(response.body).to include("Ensure each line item has a item selected AND a quantity greater than 0.")
        expect(response.body).to include("Still need help? Please contact your essentials bank, #{partner.organization.name}")
        expect(response.body).to include("Our email on record for them is:")
        expect(response.body).to include(partner.organization.email)
      end
    end

    context "when a request has only a comment" do
      it "is valid" do
        request_attributes[:request][:item_requests_attributes] = {
          "0" => {quantity: nil, item_id: nil}
        }

        expect { post partners_requests_path, params: request_attributes }.to change { Request.count }.by(1)
        expect(response).to redirect_to(partners_request_path(Request.last.id))
        expect(response.request.flash[:success]).to eql "Request was successfully created."
      end
    end

    context "when a has an empty row" do
      it "is valid" do
        request_attributes[:request][:item_requests_attributes]["0"] = {quantity: nil, item_id: nil}

        expect { post partners_requests_path, params: request_attributes }.to change { Request.count }.by(1)
        expect(response).to redirect_to(partners_request_path(Request.last.id))
        expect(response.request.flash[:success]).to eql "Request was successfully created."
      end
    end

    context "when signed in as an organization admin" do
      context "when given valid parameters" do
        before { sign_in(org_admin) }
        subject { post partners_requests_path, params: request_attributes.merge(partner_id:) }

        context "when corresponding partner belongs to the organization" do
          let(:org_admin) { create(:organization_admin, organization:) }

          context "when param partner_id is present" do
            let(:partner_id) { partner.id }

            it "should redirect to the show page" do
              expect { subject }.to change { Request.count }.by(1)
              expect(response).to redirect_to(request_path(Request.last.id))
              expect(response.request.flash[:success]).to eql "Request was successfully created."
            end
          end

          context "when param partner_id is missing" do
            let(:partner_id) { "" }

            it "redirects to dashboard path and flashes an error" do
              subject
              expect(flash[:error]).to eq("That screen is not available. Please try again as a partner.")
              expect(response).to redirect_to(dashboard_path)
            end
          end
        end

        context "when corresponding partner doesn't belong to the organization" do
          let(:new_organization) { create(:organization) }
          let(:org_admin) { create(:organization_admin, organization: new_organization) }
          let(:partner_id) { partner.id }

          it "redirects to dashboard path and flashes an error" do
            subject
            expect(flash[:error]).to eq("That screen is not available. Please try again as a partner.")
            expect(response).to redirect_to(dashboard_path)
          end
        end
      end
    end

    context "when signed in as an organization user" do
      let(:org_user) { create(:user) }
      before { sign_in(org_user) }

      it "redirects to dashboard path and flashes an error" do
        subject
        expect(flash[:error]).to eq("That screen is not available. Please try again as a partner.")
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end

  describe "GET #print_unfulfilled" do
    let(:item1) { create(:item, name: "Good item") }
    let(:item2) { create(:item, name: "Crap item") }
    let(:partner1) { create(:partner, organization: organization) }
    let(:partner_user) { partner1.primary_user }
    let!(:pending_request) { create(:request, :with_item_requests, :pending, partner: partner1, request_items: [{ item_id: item1.id, quantity: '100' }]) }
    let!(:started_request) { create(:request, :with_item_requests, :started, partner: partner1, request_items: [{ item_id: item2.id, quantity: '50' }]) }
    let!(:discarded_request) { create(:request, :with_item_requests, :discarded, partner: partner1, request_items: [{ item_id: item2.id, quantity: '30' }]) }
    let!(:fulfilled_request) { create(:request, :with_item_requests, :fulfilled, partner: partner1, request_items: [{ item_id: item2.id, quantity: '20' }]) }

    before do
      partner_user.add_role(Role::ORG_ADMIN, organization)
      sign_in(partner_user)
      get print_unfulfilled_requests_path(format: :pdf)
    end

    it "returns a PDF file" do
      PDF::Reader.new(StringIO.new(response.body))
      expect(response.content_type).to eq('application/pdf')
      expect(response.headers['Content-Disposition']).to include('inline')
      expect(response.body.bytes[0..3]).to eq('%PDF'.bytes)
    end

    it "includes only 'pending' and 'started' requests" do
      pdf_content = PDF::Reader.new(StringIO.new(response.body))
      # this is a semi-lazy check, since we're ensuring 1 page for each request. In real world,
      # it's possible that there could be more than 1 page per request if the request is long.

      expect(pdf_content.page_count).to eq(2)
    end

    it "calls compute_and_render with the 2 matching requests" do
      # Create a double for the PDF instance
      pdf_double = double("PicklistsPdf")

      # Expect PicklistsPdf.new to be called with correct args and return our double
      expect(PicklistsPdf).to receive(:new)
        .with(organization, kind_of(ActiveRecord::Relation))
        .and_return(pdf_double)

      # Expect compute_and_render to be called on our double and return some PDF data
      # We don't really care about the content, the PDF model is tested elsewhere
      expect(pdf_double).to receive(:compute_and_render)
        .and_return("fake pdf content")

      # Make the request
      get print_unfulfilled_requests_path(format: :pdf)

      # Verify the response
      expect(response).to be_successful
      expect(response.content_type).to eq("application/pdf")
      expect(response.headers["Content-Disposition"]).to include("inline")
      expect(response.body).to eq("fake pdf content")
    end
  end

  describe "GET #print_picklist" do
    let(:organization) { create(:organization) }
    let(:partner) { create(:partner, organization: organization) }
    let(:partner_user) { partner.primary_user }
    let(:org_admin) { create(:organization_admin, organization: organization) }
    let(:request) { create(:request, :with_item_requests, organization: organization, partner: partner, partner_user: org_admin) }

    before do
      sign_in(org_admin)
    end

    it "generates a PDF for a single request" do
      # Create a double for the PDF instance
      pdf_double = double("PicklistsPdf")

      # Expect PicklistsPdf.new to be called with correct args and return our double
      expect(PicklistsPdf).to receive(:new)
        .with(organization, [request])
        .and_return(pdf_double)

      # Expect compute_and_render to be called on our double and return some PDF data
      expect(pdf_double).to receive(:compute_and_render)
        .and_return("fake pdf content")

      # Make the request
      get print_picklist_request_path(request, format: :pdf)

      # Verify the response
      expect(response).to be_successful
      expect(response.content_type).to eq("application/pdf")
      expect(response.headers["Content-Disposition"]).to include("inline")
      expect(response.headers["Content-Disposition"]).to include("Picklists_")
      expect(response.body).to eq("fake pdf content")
    end

    it "includes correct associations in the query" do
      pdf_double = double("PicklistsPdf", compute_and_render: "pdf content")

      expect(PicklistsPdf).to receive(:new) do |org, requests|
        # Verify the request includes the necessary associations
        expect(requests.first.association(:item_requests)).to be_loaded
        expect(requests.first.association(:partner)).to be_loaded
        expect(requests.first.partner.association(:profile)).to be_loaded
        pdf_double
      end

      get print_picklist_request_path(request, format: :pdf)
    end
  end

  describe 'POST #validate' do
    it 'should handle missing CSRF gracefully' do
      sign_in(partner_user)

      ActionController::Base.allow_forgery_protection = true
      post validate_partners_requests_path
      ActionController::Base.allow_forgery_protection = false

      expect(JSON.parse(response.body)).to eq({'valid' => false})
      expect(response.status).to eq(200)
    end
  end
end
