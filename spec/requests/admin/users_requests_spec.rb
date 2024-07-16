RSpec.describe "Admin::UsersController", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }
  let(:super_admin) { create(:super_admin, organization: organization) }

  let(:default_params) do
    { organization_name: organization.id }
  end

  let(:org) { create(:organization, name: 'Org ABC') }
  let(:partner) { create(:partner, name: 'Partner XYZ', organization: org) }
  let(:user) { create(:user, organization: org, name: 'User 123') }

  context "When logged in as a super admin" do
    before do
      sign_in(super_admin)
      AddRoleService.call(user_id: user.id, resource_type: Role::PARTNER, resource_id: partner.id)
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
          patch admin_user_path(user), params: { user: default_params.merge(organization_id: user.organization.id,
            name: 'New User 123', email: 'random@gmail.com') }
          expect(response).to redirect_to admin_users_path
          expect(flash[:notice]).to eq("New User 123 updated!")
        end
      end

      context 'with errors' do
        it "redirects back with no organization_id flash message" do
          patch admin_user_path(user), params: { user: { name: 'New User 123' } }
          expect(response).to redirect_to(edit_admin_user_path)
          expect(flash[:error]).to eq('Please select an organization for the user.')
        end

        it "redirects back with no role found flash message" do
          patch admin_user_path(user), params: { user: { name: 'New User 123', organization_id: -1 } }
          expect(response).to redirect_to(edit_admin_user_path)
          expect(flash[:error]).to eq('Error finding a role within the provided organization')
        end
      end
    end

    describe '#add_role' do
      context 'with no errors' do
        it 'should call the service and redirect back' do
          allow(AddRoleService).to receive(:call)
          post admin_user_add_role_path(user_id: user.id,
            resource_type: Role::ORG_ADMIN,
            resource_id: org.id),
            headers: { 'HTTP_REFERER' => '/back/url'}
          expect(AddRoleService).to have_received(:call).with(user_id: user.id.to_s,
            resource_type: Role::ORG_ADMIN.to_s,
            resource_id: org.id.to_s)
          expect(flash[:notice]).to eq('Role added!')
          expect(response).to redirect_to('/back/url')
        end
      end

      context 'with errors' do
        it 'should redirect back with error' do
          allow(AddRoleService).to receive(:call).and_raise('OH NOES')
          post admin_user_add_role_path(user_id: user.id,
            resource_type: Role::ORG_ADMIN,
            resource_id: org.id),
            headers: { 'HTTP_REFERER' => '/back/url'}
          expect(AddRoleService).to have_received(:call).with(user_id: user.id.to_s,
            resource_type: Role::ORG_ADMIN.to_s,
            resource_id: org.id.to_s)
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

      it "preloads organizations" do
        get new_admin_user_path
        expect(assigns(:organizations)).to eq(Organization.all.alphabetized)
      end
    end

    describe "POST #create" do
      it "returns http success" do
        post admin_users_path, params: { user: { email: organization.email, organization_id: organization.id } }
        expect(response).to redirect_to(admin_users_path)
      end

      it "preloads organizations" do
        post admin_users_path, params: { user: { organization_id: organization.id } }
        expect(assigns(:organizations)).to eq(Organization.all.alphabetized)
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
