RSpec.describe Partners::IndividualsRequestsController, type: :request do
  let(:organization) { create(:organization, :with_items) }
  let(:partner) { create(:partner, status: :approved, organization: organization) }
  let(:partner_user) { partner.primary_user }

  let(:items_to_select) { partner_user.partner.organization.valid_items.sample(3) }
  let(:items_attributes) do
    items_to_select.each_with_index.each_with_object({}) do |(item, index), hash|
      hash[index.to_s] = {
        item_id: item[:id],
        person_count: Faker::Number.within(range: 5..25)
      }
      hash
    end
  end
  let(:comments) { "This is a comment" }
  let(:params) do
    {
      partners_family_request:
      {
        items_attributes: items_attributes,
        comments: comments
      }
    }
  end

  before { sign_in(partner_user) }

  describe "GET #new" do
    subject { get new_partners_individuals_request_path }

    it "does not allow deactivated partners" do
      partner.update!(status: :deactivated)

      expect(subject).to redirect_to(partners_requests_path)
    end

    it "does not allow partners not verified" do
      partner.update!(status: :uninvited)

      expect(subject).to redirect_to(partners_requests_path)
    end

    context "when first reaching the new page" do
      let(:requestable_items) { [["Item 1", 1], ["Item 2", 2], ["Item 3", 3]] }
      before do
        allow_any_instance_of(PartnerFetchRequestableItemsService).to receive(:call).and_return(requestable_items)
      end

      it "has the correct select fields" do
        subject

        expect(response).to be_successful
        expect(response.body).to include('<option value="">Select an item</option>')
        requestable_items.each do |item, index|
          expect(response.body).to include("<option value=\"#{index}\">#{item}</option>")
        end
      end
    end
  end

  describe "POST #create" do
    subject { post partners_individuals_requests_path, params: params }

    it "does not allow deactivated partners" do
      partner.update!(status: :deactivated)

      expect(subject).to redirect_to(partners_requests_path)
    end

    it "does not allow partners not verified" do
      partner.update!(status: :uninvited)

      expect(subject).to redirect_to(partners_requests_path)
    end

    context "when the request is valid" do
      it "submits the request" do
        expect { subject }.to change { Request.count }.by(1)
        expect(response).to redirect_to(partners_request_path(Request.last.id))
        expect(response.request.flash[:success]).to eql "Request was successfully created."
      end
    end

    context "when the request has invalid inputs" do
      it "shows an error" do
        params[:partners_family_request][:items_attributes]["0"][:person_count] = -8
        expect { post partners_individuals_requests_path, params: params }.to_not change { Request.count }

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

      it "has the correct select fields" do
        params[:partners_family_request][:items_attributes]["0"][:person_count] = -8
        post partners_individuals_requests_path, params: params

        expect(response.body).to include('<option value="">Select an item</option>')
        requestable_items.each do |item, index|
          expect(response.body).to include("<option value=\"#{index}\">#{item}</option>")
        end
      end
    end

    context "when a request is empty" do
      let(:params) do
        {
          partners_family_request:
          {
            items_attributes: nil,
            comments: nil
          }
        }
      end

      it "is invalid" do
        expect { post partners_individuals_requests_path, params: params }.to_not change { Request.count }

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
        params[:partners_family_request][:items_attributes] = nil

        expect { post partners_individuals_requests_path, params: params }.to change { Request.count }.by(1)
        expect(response).to redirect_to(partners_request_path(Request.last.id))
        expect(response.request.flash[:success]).to eql "Request was successfully created."
      end
    end

    context "when a request has an empty row" do
      it "is valid" do
        params[:partners_family_request][:items_attributes]["0"] = {person_count: nil, item_id: nil}

        expect { post partners_individuals_requests_path, params: params }.to change { Request.count }.by(1)
        expect(response).to redirect_to(partners_request_path(Request.last.id))
        expect(response.request.flash[:success]).to eql "Request was successfully created."
      end
    end
  end
end
