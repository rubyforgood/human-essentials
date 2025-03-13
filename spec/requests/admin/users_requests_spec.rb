RSpec.describe "Admin::UsersController", type: :request do
  let(:organization) { create(:organization, name: "Org ABC") }
  let(:user) { create(:user, organization: organization, name: "User 123") }
  let(:organization_admin) { create(:organization_admin, organization: organization) }
  let(:super_admin) { create(:super_admin, organization: organization) }
  let(:partner) { create(:partner, name: 'Partner XYZ', organization: organization) }

  context "When logged in as a super admin" do
    before do
      sign_in(super_admin)
      AddRoleService.call(user_id: user.id, resource_type: Role::PARTNER, resource_id: partner.id)
    end

    describe "GET #index" do
      it "renders index template and shows banks and partners correctly" do
        AddRoleService.call(user_id: user.id, resource_type: Role::ORG_ADMIN, resource_id: organization.id)
        get admin_users_path

        expect(response).to render_template(:index)

        page = Nokogiri::HTML(response.body)
        banks_and_partners = page.at_xpath("//*[contains(text(), \"#{user.email}\")]/../td[1]").text.strip
        expect(banks_and_partners).to eq("Org ABC, Partner XYZ")
      end
    end

    describe "GET #edit" do
      it "renders edit template and shows roles" do
        get edit_admin_user_path(user)
        expect(response).to render_template(:edit)
        expect(response.body).to include('User 123')
        expect(response.body).to include('Org ABC')
        expect(response.body).to include('Partner XYZ')
      end
    end

    describe "PATCH #update" do
      context 'with no errors' do
        it "renders index template with a successful update flash message" do
          patch admin_user_path(user), params: { user: { name: 'New User 123', email: 'random@gmail.com' } }
          expect(response).to redirect_to admin_users_path
          expect(flash[:notice]).to eq("New User 123 updated!")
        end
      end

      context 'with errors' do
        it "redirects back with flash message" do
          patch admin_user_path(user), params: { user: { name: 'New User 123', email: "invalid_email" } }
          expect(response).to redirect_to(edit_admin_user_path)
          expect(flash[:error]).to eq("Something didn't work quite right -- try again?")
        end
      end
    end

    describe '#add_role' do
      context 'with no errors' do
        it 'should call the service and redirect back' do
          allow(AddRoleService).to receive(:call)
          post admin_user_add_role_path(user_id: user.id,
            resource_type: Role::ORG_ADMIN,
            resource_id: organization.id),
            headers: { 'HTTP_REFERER' => '/back/url'}
          expect(AddRoleService).to have_received(:call).with(user_id: user.id.to_s,
            resource_type: Role::ORG_ADMIN.to_s,
            resource_id: organization.id.to_s)
          expect(flash[:notice]).to eq('Role added!')
          expect(response).to redirect_to('/back/url')
        end
      end

      context 'with errors' do
        it 'should redirect back with error' do
          allow(AddRoleService).to receive(:call).and_raise('OH NOES')
          post admin_user_add_role_path(user_id: user.id,
            resource_type: Role::ORG_ADMIN,
            resource_id: organization.id),
            headers: { 'HTTP_REFERER' => '/back/url'}
          expect(AddRoleService).to have_received(:call).with(user_id: user.id.to_s,
            resource_type: Role::ORG_ADMIN.to_s,
            resource_id: organization.id.to_s)
          expect(flash[:alert]).to eq('OH NOES')
          expect(response).to redirect_to('/back/url')
        end
      end
    end

    describe '#remove_role' do
      context 'with no errors' do
        it 'should call the service and redirect back' do
          allow(RemoveRoleService).to receive(:call)
          delete admin_user_remove_role_path(user_id: user.id,
            role_id: 123),
            headers: { 'HTTP_REFERER' => '/back/url'}
          expect(RemoveRoleService).to have_received(:call).with(user_id: user.id.to_s,
            role_id: '123')
          expect(flash[:notice]).to eq('Role removed!')
          expect(response).to redirect_to('/back/url')
        end
      end

      context 'with errors' do
        it 'should redirect back with error' do
          allow(RemoveRoleService).to receive(:call).and_raise('OH NOES')
          delete admin_user_remove_role_path(user_id: user.id,
            role_id: 123),
            headers: { 'HTTP_REFERER' => '/back/url'}
          expect(RemoveRoleService).to have_received(:call).with(user_id: user.id.to_s,
            role_id: '123')
          expect(flash[:alert]).to eq('OH NOES')
          expect(response).to redirect_to('/back/url')
        end
      end
    end

    describe "GET #new" do
      it "renders new template" do
        get new_admin_user_path
        expect(response).to render_template(:new)
      end

      it "preloads roles" do
        get new_admin_user_path
        expect(assigns(:resources)).to eq(Role::TITLES.invert)
      end
    end

    describe "POST #create" do
      it "creates an org user" do
        post admin_users_path, params: {
          user: { name: "New Org User", email: organization.email },
          resource_type: Role::ORG_USER,
          resource_id: organization.id
        }
        expect(response).to redirect_to(admin_users_path)
        new_user = User.find_by(name: "New Org User")
        expect(new_user).not_to eq(nil)
        expect(new_user.has_role?(Role::ORG_USER, organization)).to be_truthy
        expect(new_user.has_role?(Role::ORG_ADMIN, organization)).to be_falsey
      end

      it "creates an org admin" do
        post admin_users_path, params: {
          user: { name: "New Org Admin", email: organization.email },
          resource_type: Role::ORG_ADMIN,
          resource_id: organization.id
        }
        expect(response).to redirect_to(admin_users_path)
        new_user = User.find_by(name: "New Org Admin")
        expect(new_user).not_to eq(nil)
        expect(new_user.has_role?(Role::ORG_USER, organization)).to be_truthy
        expect(new_user.has_role?(Role::ORG_ADMIN, organization)).to be_truthy
      end

      it "creates a partner user" do
        post admin_users_path, params: {
          user: { name: "New Partner User", email: organization.email },
          resource_type: Role::PARTNER,
          resource_id: partner.id
        }
        expect(response).to redirect_to(admin_users_path)
        new_user = User.find_by(name: "New Partner User")
        expect(new_user).not_to eq(nil)
        expect(new_user.has_role?(Role::PARTNER, partner)).to be_truthy
      end

      it "creates a super admin" do
        post admin_users_path, params: {
          user: { name: "New Super Admin", email: organization.email },
          resource_type: Role::SUPER_ADMIN
        }
        expect(response).to redirect_to(admin_users_path)
        new_user = User.find_by(name: "New Super Admin")
        expect(new_user).not_to eq(nil)
        expect(new_user.has_role?(Role::SUPER_ADMIN)).to be_truthy
      end

      it "preloads organizations" do
        post admin_users_path, params: { user: { organization_id: organization.id } }
        expect(assigns(:organizations)).to eq(Organization.all.alphabetized)
      end

      it "preloads roles" do
        post admin_users_path, params: { user: { organization_id: organization.id } }
        expect(assigns(:resources)).to eq(Role::TITLES.invert)
      end

      context "with missing role type" do
        it "redirects back with flash message" do
          post admin_users_path, params: { user: { name: "ABC", email: organization.email } }
          expect(response).to render_template("admin/users/new")
          expect(flash[:error]).to eq("Failed to create user: Please select a role for the user.")
        end
      end

      context "with missing resource id" do
        it "redirects back with flash message" do
          post admin_users_path, params: { user: { name: "ABC", email: organization.email }, resource_type: Role::ORG_ADMIN }
          expect(response).to render_template("admin/users/new")
          expect(flash[:error]).to eq("Failed to create user: Please select an associated resource for the role.")
        end
      end
    end
  end

  context "When logged in as an organization_admin" do
    before do
      sign_in organization_admin
      create(:organization)
    end

    describe "GET #new" do
      it "redirects" do
        get new_admin_user_path
        expect(response).to redirect_to(dashboard_path)
      end
    end

    describe "POST #create" do
      it "redirects" do
        post admin_users_path, params: { user: { organization_id: organization.id } }
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end

  context "When logged in as a non-admin user" do
    before do
      sign_in user
      create(:organization)
    end

    describe "GET #new" do
      it "redirects" do
        get new_admin_user_path
        expect(response).to redirect_to(dashboard_path)
      end
    end

    describe "POST #create" do
      it "redirects" do
        post admin_users_path, params: { user: { organization_id: organization.id } }
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end
end
