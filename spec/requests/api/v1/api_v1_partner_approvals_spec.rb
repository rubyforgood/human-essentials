require 'rails_helper'

RSpec.describe "API::V1::PartnerApprovals", type: :request do
  describe "POST /api/v1/partner_approvals" do
    let!(:partner) { create(:partner) }

    context "with a valid API key" do
      subject do
        headers = {
          "ACCEPT" => "application/json",
          "X-Api-Key" => ENV["PARTNER_KEY"]
        }

        params = {
          partner: {
            diaper_partner_id: partner.id
          }
        }

        post api_v1_partner_approvals_path, params: params, headers: headers
      end

      it "returns HTTP created" do
        subject
        expect(response).to have_http_status(:ok)
      end
    end

    context "without a valid API key" do
      before do
        headers = {
          "ACCEPT" => "application/json",
          "X-Api-Key" => "not_valid"
        }

        params = {
          request: {
            diaper_partner_id: partner.id
          }
        }

        post api_v1_partner_approvals_path, params: params, headers: headers
      end

      it "returns HTTP forbidden" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end