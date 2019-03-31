require 'rails_helper'

RSpec.describe "API::V1::FamilyRequests", type: :request do
  describe "POST /api/v1/family_requests" do
    let!(:organization) { create(:organization) }
    let!(:partner) { create(:partner, organization: organization) }
    let(:request_items) do
      Item.all.pluck(:id).sample(3).collect do |k|
        {
          "item_id" => k,
          "person_count" => rand(3..10)
        }
      end
    end

    context "with a valid API key" do
      subject do
        headers = {
          "ACCEPT" => "application/json",
          "Content-Type" => "application/json",
          "X-Api-Key" => ENV["PARTNER_KEY"]
        }

        params = {
          organization_id: organization.id,
          partner_id: partner.id,
          comments: "please and thank you",
          requested_items: request_items
        }.to_json

        post api_v1_family_requests_path, params: params, headers: headers
      end

      it "returns HTTP created" do
        subject
        expect(response).to have_http_status(:created)
      end

      it "creates a new Request" do
        expect { subject }.to change { Request.count }.by(1)
      end

      it "returns the request actually created" do
        subject
        returned_body = JSON.parse(response.body)
        expected_items = request_items.map do |item|
          {
            'item_id' => item['item_id'],
            'count' => item['count'] * 50
          }
        end
        expect(returned_body['requested_items']).to eq(expected_items)
      end
    end

    context "without a valid API key" do
      before do
        headers = {
          "ACCEPT" => "application/json",
          "X-Api-Key" => "blarg"
        }

        params = {
          request: {
            organization_id: organization.id,
            partner_id: partner.id,
            comments: "please and thank you",
            request_items: random_keys(3).collect { |k| [k, rand(3..10)] }.to_h
          }
        }

        post api_v1_partner_requests_path, params: params, headers: headers
      end

      it "returns HTTP forbidden" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET /api/v1/family_request/:id" do
    let(:organization) { create(:organization) }

    context "with a valid API key" do
      context 'with a valid organization id' do
        headers = {
          "ACCEPT" => "application/json",
          "X-Api-Key" => ENV["PARTNER_KEY"]
        }
        before { get api_v1_partner_request_path(organization.id), headers: headers }

        it "returns HTTP success" do
          expect(response).to be_successful
        end

        it "returns a body with valid items" do
          expect(JSON.parse(response.body)).to match_array(organization.valid_items)
        end
      end

      context "without a valid organization id" do
        headers = {
          "ACCEPT" => "application/json",
          "X-Api-Key" => ENV["PARTNER_KEY"]
        }
        before { get api_v1_partner_request_path('foo'), headers: headers }

        it "returns HTTP bad request" do
          expect(response).to have_http_status(:bad_request)
        end
      end
    end

    context "without a valid API key" do
      headers = {
        "ACCEPT" => "application/json",
        "X-Api-Key" => "blarg"
      }

      before { get api_v1_partner_request_path(organization.id), headers: headers }

      it "returns HTTP forbidden" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end


