require "rails_helper"

RSpec.describe "Sessions", type: :request, order: :defined do
  context "Sign in as user without logging off as an admin" do
    before do
      # sign in as an org_admin
      sign_in(@organization_admin)
      # sign in as a user without explicitly logging as org_admin
      sign_in(@user)
    end

    it "cannot access admin dashboard" do
      get root_path
      expect(response).not_to redirect_to(admin_dashboard_url(@organization_admin))
    end

    it "properly accesses the organization dashboard" do
      get root_path
      expect(response).to redirect_to(dashboard_url(@organization))
    end
  end
end
