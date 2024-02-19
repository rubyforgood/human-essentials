RSpec.describe "Admin", type: :request do
  context "while signed in as a super admin" do
    before do
      sign_in(@super_admin_no_org)
    end

    it "allows a user to load the dashboard" do
      get admin_dashboard_path
      expect(response).to be_successful
    end

    context "with rendered views" do
      let!(:users_list) { create_list(:user, 25) }
      let!(:user) { create(:user, name: "Name Not Provided") }

      it "shows a logout button" do
        get admin_dashboard_path
        expect(response.body).to match(/log out/im)
      end

      it "shows the recently added users email" do
        get admin_dashboard_path
        expect(response).to have_http_status(:success)
        expect(response.body).to match(/20 New Users/im)
        expected_path = edit_admin_user_path(user, organization_id: "admin")
        expect(response.body).to include(CGI.escapeHTML(expected_path))
      end
    end
  end

  context "while signed in as a non-super-admin" do
    it "disallows dashboard access, redirecting to the normal dashboard" do
      [@organization_admin, @user].each do |u|
        sign_in(u)
        get admin_dashboard_path
        expect(response).to redirect_to(dashboard_path)
        expect(response).to have_error
      end
    end
  end
end
