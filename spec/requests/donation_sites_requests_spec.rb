require "rails_helper"

RSpec.describe "DonationSites", type: :request do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  describe "while signed in" do
    before do
      sign_in(@user)
    end

    describe "GET #index" do
      subject do
        get donation_sites_path(default_params.merge(format: response_format))
        response
      end

      before do
        create(:donation_site)
      end

      context "html" do
        let(:response_format) { 'html' }

        it { is_expected.to be_successful }
      end

      context "csv" do
        let(:response_format) { 'csv' }

        it { is_expected.to be_successful }
      end
    end
  end
end
