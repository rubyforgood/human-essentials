require "rails_helper"

RSpec.describe "Users", type: :request do
  let(:partner) { create(:partner) }
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  before do
    sign_in(@user)
  end

  describe "GET #index" do
    it "returns http success" do
      get users_path(default_params)
      expect(response).to be_successful
    end
  end

  describe "GET #new" do
    it "returns http success" do
      get new_user_path(default_params)
      expect(response).to be_successful
    end
  end

  describe "GET #switch_to_partner_role" do
    let(:admin_user) do
      org = create(:organization)
      create(:user, organization: org, name: "ADMIN USER")
    end
    context "with a partner role" do
      it "should redirect to the partner path" do
        @user.add_role(Role::PARTNER, Partners::Partner.find_by(partner_id: partner.id))
        get switch_to_role_users_path(@organization,
          role_id: @user.roles.find { |r| r.name == Role::PARTNER.to_s })
        # all bank controllers add organization_id to all routes - there's no way to
        # avoid it
        expect(response).to redirect_to(partners_dashboard_path(organization_id: @organization.to_param))
      end
    end

    context "without a partner role" do
      it "should redirect to the root path with an error" do
        get switch_to_role_users_path(@organization, role_id: admin_user.roles.first.id)
        message = "Attempted to switch to a role that doesn't belong to you!"
        expect(flash[:alert]).to eq(message)
        expect(response).to redirect_to(root_path(@organization))
      end
    end
  end
end
