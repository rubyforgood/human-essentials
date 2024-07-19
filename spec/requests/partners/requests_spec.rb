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
  end

  describe "POST #create" do
    subject { post partners_requests_path, params: request_attributes }
    let(:item1) { create(:item, name: "First item", organization: organization) }

    let(:request_attributes) do
      {
        request: {
          comments: Faker::Lorem.paragraph,
          item_requests_attributes: {
            "0" => {
              item_id: item1.id,
              quantity: Faker::Number.within(range: 4..13)
            }
          }
        }
      }
    end

    before do
      sign_in(partner_user)
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
  end
end
