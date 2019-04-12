require 'rails_helper'

RSpec.describe "API::V1::FamilyRequests", type: :request do
  describe "POST /api/v1/family_requests" do
    let(:items) { Item.all.sample(3) }
    let(:request_items) do
      items.collect do |item|
        {
          "item_id" => item.id,
          "person_count" => rand(3..10)
        }
      end
    end

    context "with a valid API key" do
      before do
        allow_any_instance_of(API::V1::FamilyRequestsController).to receive(:api_key_valid?).and_return(true)
      end

      subject do
        headers = {
          "ACCEPT" => "application/json",
          "Content-Type" => "application/json",
          "X-Api-Key" => "some-fake-key"
        }

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
            organization_id: @organization.id,
            partner_id: @partner.id,
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
