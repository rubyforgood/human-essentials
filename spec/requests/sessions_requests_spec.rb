require "rails_helper"

RSpec.describe "Sessions", type: :request, order: :defined do
  context "Sign in as an org_admin before signing in as a partner" do
    before do
      # sign in as an org_admin
      sign_in(@organization_admin)

      # create a basic test org and partner
      
      org = Organization.create!(
        name: "Test Organization",
        short_name: "testorg",
        email: "testorg@example.com",
        enable_child_based_requests: true,
        enable_individual_requests: true,
        enable_quantity_based_requests: true
      )
        
      partner = Partner.create!(
        name: "Test Partner",
        email: "test_partner@example.com",
        organization_id: org.id,
        status: Partner.statuses[:invited] # Set the status as invited
      )

      # # sign in as a partner
      user = User.create!(
        email: "partner123@example.com",
        name: "Test Partner",
        password: "password!",
        organization_id: org.id,
        partner_id: partner.id
      )

      # print(p)
      user.add_role(:partner, partner)
      sign_in(user)

      # post "/users/sign_in/",
      #   params: {user: {email: "partner123@example.com", password: "password!"}}
    end

    it "successfully reach the partners dashboard" do
      get partner_user_root_path
      # puts(response.body)
      expect(response).to be_successful
    end

    it "cannot access the admin dashboard" do
      get admin_dashboard_path
      print(admin_dashboard_path)
      expect(response).not_to be_successful
    end
  end
end
