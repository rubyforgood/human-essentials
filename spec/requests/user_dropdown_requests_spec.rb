RSpec.describe "UsernameDropdown", type: :request do
  let(:organization) { create(:organization) }

  describe "My Co-Workers link visibility" do
    context "when user does not have partner role" do
      let(:user) { create(:user, organization: organization) }

      before do
        user.add_role(Role::ORG_ADMIN, organization)
        sign_in(user)
      end

      it "does not show the My Co-Workers link" do
        get dashboard_path
        expect(response.body).not_to include("My Co-Workers")
      end
    end
  end
end
