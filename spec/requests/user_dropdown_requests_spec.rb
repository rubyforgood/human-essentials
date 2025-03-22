require "rails_helper"

RSpec.describe "User Dropdown", type: :request do
  describe "dropdown menu content" do
    it "doesn't show My Co-Workers for org admins who are not partners" do
      organization = create(:organization)
      user = create(:organization_admin, organization: organization)

      expect(user.has_role?(Role::ORG_ADMIN, user.organization)).to be true
      expect(user.has_role?(:partner)).to be false

      sign_in(user)

      get dashboard_path

      expect(response).to be_successful
      expect(response.body).not_to include("My Co-Workers")
    end
  end
end
