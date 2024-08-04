RSpec.describe "Sessions", type: :request, order: :defined do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  context "Sign in as user without logging off as an admin" do
    before do
      # sign in as an org_admin
      sign_in(organization_admin)
      # sign in as a user without explicitly logging as org_admin
      sign_in(user)
    end

    it "cannot access admin dashboard" do
      get root_path
      expect(response).not_to redirect_to(admin_dashboard_url(organization_admin))
    end

    it "properly accesses the organization dashboard" do
      get root_path
      expect(response).to redirect_to(dashboard_url)
    end
  end

  describe "POST #create" do
    let(:partner_user) { create(:partner_user) }
    let(:partner_role) { partner_user.roles.first }
    let(:organization) { create(:organization) }

    context "when an org_admin with a last used partner role" do
      before do
        partner_user.add_role(Role::ORG_ADMIN, organization)
        UsersRole.set_last_role_for(partner_user, partner_role)
      end

      it "signs in with partner role" do
        post user_session_path, params: {user: {email: partner_user.email, password: "password!"}}
        get root_path
        expect(response).to redirect_to(partners_dashboard_url)
      end
    end

    context "when last used role is revoked" do
      before do
        UsersRole.set_last_role_for(partner_user, partner_role)
        partner_role.destroy
      end

      it "does not sign in as partner_user" do
        post user_session_path, params: {user: {email: partner_user.email, password: "password!"}}
        get root_path
        expect(response).to_not redirect_to(partners_dashboard_url)
      end
    end

    context "when partner_role saved in session" do
      before do
        post user_session_path, params: {user: {email: partner_user.email, password: "password!"}}
        get root_path
      end

      context "when org_admin role is added and no last_role exists" do
        before { partner_user.add_role(Role::ORG_ADMIN, organization) }

        it "prefers session role" do
          post user_session_path, params: {user: {email: partner_user.email, password: "password!"}}
          get root_path

          expect(response).to redirect_to(partners_dashboard_url)
        end

        context "when session role is revoked" do
          before { partner_role.destroy }

          it "prefers org_admin" do
            post user_session_path, params: {user: {email: partner_user.email, password: "password!"}}
            get root_path

            expect(response).to redirect_to(dashboard_url)
          end
        end
      end

      context "when org_admin role is added, no last_role exists" do
        it "prefers partner" do
          partner_user.add_role(Role::ORG_ADMIN, organization)

          post user_session_path, params: {user: {email: partner_user.email, password: "password!"}}
          get root_path

          expect(response).to redirect_to(partners_dashboard_url)
        end
      end
    end

    context "without a previously used role" do
      before do
        partner_user.add_role(Role::ORG_ADMIN, organization)
        expect(partner_user.last_role).to be_nil
      end

      it "signs in as org_admin role" do
        post user_session_path, params: {user: {email: partner_user.email, password: "password!"}}
        get root_path
        expect(response).to redirect_to(dashboard_url)
      end
    end
  end
end
