require 'rails_helper'

RSpec.describe "Dashboard", type: :request do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  context "While signed in" do
    before do
      sign_in(@user)
    end

    describe "GET #show" do
      it "returns http success" do
        get dashboard_path(default_params)
        expect(response).to be_successful
        expect(response.body).not_to include('switch_to_partner_role')
      end

      context 'with both roles' do
        it 'should include the switch link' do
          partner = FactoryBot.create(:partner)
          @user.add_role(Role::PARTNER, partner)
          get dashboard_path(default_params)
          expect(response.body).to include('switch_to_role')
        end
      end

      context "for another org" do
        it "requires authorization" do
          # nother org
          get dashboard_path(organization_id: create(:organization).to_param)
          expect(response).to be_redirect
        end
      end
    end
  end

  context "While not signed in" do
    it "redirects for authentication" do
      get dashboard_path(organization_id: create(:organization).to_param)
      expect(response).to be_redirect
    end
  end
end
