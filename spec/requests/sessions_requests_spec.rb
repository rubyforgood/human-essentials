require "rails_helper"

RSpec.describe "Sessions", type: :request, order: :defined do
  context "Sign in as an org_admin before signing in as a partner" do
    before do
      # sign in as an org_admin
      sign_in(@organization_admin)

      # sign in as a partner
      user = User.create!(
        email: "partner123@example.com",
        name: "Test Partner",
        password: "password!"
      )
      user.add_role(:partner, create(:organization))
      post "/users/sign_in/",
        params: {user: {email: "partner123@example.com", password: "password!"}}
    end

    it "successfully reach the partners dashboard" do
      get dashboard_path
      expect(response).to be_successful
    end

    it "cannot access the admin dashboard" do
      get admin_dashboard_path
      expect(response).not_to be_successful
    end
  end
end
