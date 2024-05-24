require "rails_helper"

RSpec.describe "Users", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  let(:partner) { create(:partner) }

  before do
    sign_in(user)
  end

  describe "GET #index" do
    it "returns http success" do
      get users_path
      expect(response).to be_successful
    end
  end

  describe "GET #new" do
    it "returns http success" do
      get new_user_path
      expect(response).to be_successful
    end
  end

  describe "POST #send_partner_user_reset_password" do
    let(:partner) { create(:partner, organization: organization) }
    let!(:user) { create(:partner_user, partner: partner, email: "me@partner.com") }
    let(:params) { { organization_name: organization.short_name, partner_id: partner.id, email: "me@partner.com" } }

    it "should send a password" do
      post partner_user_reset_password_users_path(params)
      expect(response).to redirect_to(root_path)
      expect(ActionMailer::Base.deliveries.size).to eq(1)
    end

    it "should return an error if organization does not own the partner" do
      org2 = create(:organization)
      partner.update!(organization_id: org2.id)
      post partner_user_reset_password_users_path(params)
      expect(ActionMailer::Base.deliveries.size).to eq(0)
    end

    it "should return an error if it cannot find the user" do
      user.update!(email: "some-other-email@mail.com")
      post partner_user_reset_password_users_path(params)
      expect(ActionMailer::Base.deliveries.size).to eq(0)
    end

    it "should return send a password even if case-insensitive spelling of email" do
      user.update!(email: "Me@partner.com")
      post partner_user_reset_password_users_path(params)
      expect(ActionMailer::Base.deliveries.size).to eq(1)
    end
  end

  describe "GET #switch_to_partner_role" do
    let(:admin_user) do
      org = create(:organization)
      create(:user, organization: org, name: "ADMIN USER")
    end

    context "with a partner role" do
      it "should redirect to the partner path" do
        user.add_role(Role::PARTNER, partner)
        get switch_to_role_users_path(organization,
          role_id: user.roles.find { |r| r.name == Role::PARTNER.to_s })
        expect(response).to redirect_to(partners_dashboard_path)
      end

      it "should set last_role to partner" do
        user.add_role(Role::PARTNER, partner)

        partner_role = user.roles.find { |r| r.name == Role::PARTNER.to_s }

        expect do
          get switch_to_role_users_path(organization, role_id: partner_role.id)
        end.to change(user, :last_role).from(nil).to(partner_role)
      end
    end

    context "without a partner role" do
      it "should redirect to the root path with an error" do
        get switch_to_role_users_path(organization, role_id: admin_user.roles.first.id)
        message = "Attempted to switch to a role that doesn't belong to you!"
        expect(flash[:alert]).to eq(message)
        expect(response).to redirect_to(root_path(organization))
      end
    end
  end
end
