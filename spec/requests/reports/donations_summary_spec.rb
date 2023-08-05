require 'rails_helper'

RSpec.describe "Reports::DonationsSummary", type: :request do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  describe "while signed in" do
    before do
      sign_in @user
    end

    describe "GET #index" do
      subject do
        get reports_donations_summary_index_path(default_params.merge(format: response_format))
        response
      end
      let(:response_format) { 'html' }

      it { is_expected.to have_http_status(:success) }
    end
  end

  describe "while not signed in" do
    describe "GET /index" do
      subject do
        get reports_donations_summary_index_path(default_params)
        response
      end

      it "redirect to login" do
        is_expected.to redirect_to(new_user_session_path)
      end
    end
  end
end
