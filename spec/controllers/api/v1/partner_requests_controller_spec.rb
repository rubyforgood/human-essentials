require 'rails_helper'

RSpec.describe API::V1::PartnerRequestsController, type: :controller do
  describe "show" do
    let(:organization) { create(:organization) }
    subject { get :show, params: { id: organization.id } }

    context "with a valid API key" do
      context 'with a valid organization id' do
        headers = {
          "ACCEPT" => "application/json",
          "X-Api-Key" => ENV["PARTNER_KEY"]
        }

        it "returns HTTP success" do
          request.headers.merge! headers
          expect(subject).to be_successful
        end

        it "returns a body with valid items" do
          request.headers.merge! headers
          subject
          expect(JSON.parse(response.body)).to match_array(organization.valid_items)
        end
      end

      context "without a valid organization id" do
        headers = {
          "ACCEPT" => "application/json",
          "X-Api-Key" => ENV["PARTNER_KEY"]
        }
        subject { get :show, params: { id: 'foo' } }

        it "returns HTTP bad request" do
          request.headers.merge! headers
          expect(subject).to have_http_status(:bad_request)
        end
      end
    end

    context "without a valid API key" do
      headers = {
        "ACCEPT" => "application/json",
        "X-Api-Key" => "blarg"
      }

      it "returns HTTP success" do
        request.headers.merge! headers
        expect(subject).to have_http_status(:forbidden)
      end
    end
  end
end
