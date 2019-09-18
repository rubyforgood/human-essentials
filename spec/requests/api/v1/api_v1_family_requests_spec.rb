require 'rails_helper'

RSpec.describe "API::V1::FamilyRequests", type: :request do
  describe "POST /api/v1/family_requests" do
    let(:items) { Item.active.sample(3) }
    let(:request_items) do
      items.collect do |item|
        {
          "item_id" => item.id,
          "person_count" => rand(3..10)
        }
      end
    end

    context "with a valid API key" do
      let(:headers) do
        {
          "ACCEPT" => "application/json",
          "Content-Type" => "application/json",
          "X-Api-Key" => ENV["PARTNER_KEY"]
        }
      end

      subject do
        params = {
          organization_id: @organization.id,
          partner_id: @partner.id,
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
            'count' => item['person_count'] * 50,
            'item_name' => items.find { |i| i.id == item['item_id'] }.name
          }
        end
        expect(returned_body['requested_items'])
          .to eq(expected_items.sort_by { |item| item['item_id'] })
      end

      it "returns bad request if there is an item ids mismatch" do
        params = {
          organization_id: @organization.id,
          partner_id: @partner.id,
          comments: "please and thank you",
          requested_items: request_items.unshift('item_id' => -1, person_count: 2)
        }.to_json

        post api_v1_family_requests_path, params: params, headers: headers
        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)['message'])
          .to eq('Item ids should match existing Diaper Base item ids.')
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
            organization_id: @organization.id,
            partner_id: @partner.id,
            comments: "please and thank you",
            request_items: request_items
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
    # let(:organization) { create(:organization) }

    context "with a valid API key" do
      context 'with a valid organization id' do
        headers = {
          "ACCEPT" => "application/json",
          "X-Api-Key" => ENV["PARTNER_KEY"]
        }
        before { get api_v1_partner_request_path(@organization.id), headers: headers }

        it "returns HTTP success" do
          expect(response).to be_successful
        end

        it "returns a body with valid items" do
          pending("TODO - Resolve inconsistencies")
          expect(JSON.parse(response.body)).to match_array(@organization.valid_items)
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
        "X-Api-Key" => "some-invalid-key"
      }

      before { get api_v1_partner_request_path(@organization.id), headers: headers }

      it "returns HTTP forbidden" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
