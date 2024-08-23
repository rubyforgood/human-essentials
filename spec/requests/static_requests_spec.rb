RSpec.describe "Static", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  describe "Not signed in" do
    describe "GET #index" do
      it "returns http success" do
        get root_path
        expect(response).to be_successful
      end
      it "renders the static index" do
        get root_path
        expect(response).to render_template :index
      end
    end

    describe "GET #page/privacypolicy" do
      it "renders the contact page" do
        get privacypolicy_path
        expect(response).to render_template :privacypolicy
      end
    end
  end

  describe "Signed in" do
    before do
      sign_in(user)
    end

    describe "GET #index" do
      it "redirects to organization dashboard" do
        get root_path
        expect(response).to redirect_to(dashboard_url)
      end
    end
  end

  describe "Non super user without org signed in" do
    let(:user_no_org) { User.create(email: "no-org-user@example.org2", password: "password!") }
    before do
      user_no_org.add_role(:org_user)
      sign_in(user_no_org)
    end

    describe "GET #index" do
      it "redirects to a public/403.html page" do
        get root_path
        expect(response).to redirect_to("/403")
      end
    end
  end

  describe "Super user without org signed in" do
    before do
      sign_in(create(:super_admin, organization: nil))
    end

    describe "GET #index" do
      it "redirects to admin dashboard" do
        get root_path

        expect(response).to redirect_to(admin_dashboard_url)
      end
    end
  end
end
