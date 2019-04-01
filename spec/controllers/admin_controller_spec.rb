RSpec.describe AdminController, type: :controller do
  context "while signed in as a super admin" do
    before do
      sign_in(@super_admin_no_org)
    end

    it "allows a user to load the dashboard" do
      get :dashboard
      expect(response).to be_successful
    end
    context "with rendered views" do
      render_views
      it "shows a logout button" do
        get :dashboard
        expect(response.body).to match(/log out/im)
      end
    end
  end

  # Since all Admin namespace actions inherit from AdminController, this will serve as a
  # blanket check for access for non-super-admins
  context "while signed in as a non-super-admin" do
    it "disallows dashboard access, redirecting to the normal dashboard" do
      [@organization_admin, @user].each do |u|
        sign_in(u)
        get :dashboard
        expect(response).to redirect_to(dashboard_path)
        expect(flash[:error].size).not_to be_zero
      end
    end
  end
end