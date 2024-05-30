require "rails_helper"

RSpec.describe "Organizations", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  context "While signed in as a normal user" do
    before do
      sign_in(user)
    end

    describe "GET #show" do
      before { get organization_path }

      it { expect(response).to be_successful }

      it 'load the current organization' do
        expect(assigns(:organization)).to have_attributes(
          name: organization.name,
          email: organization.email,
          url: organization.url
        )
      end
    end

    describe "GET #edit" do
      before { get edit_organization_path }

      it { expect(response).to redirect_to(dashboard_path) }
      it { expect(response).to have_error }
    end

    describe "PATCH #update" do
      let(:update_param) { { organization: { name: "Thunder Pants" } } }
      before { patch "/manage", params: update_param }

      it { expect(response).to redirect_to(dashboard_path) }
      it { expect(response).to have_error }
    end
  end

  context "While signed in as an organization admin" do
    before do
      sign_in(organization_admin)
    end

    describe "GET #edit" do
      before { get edit_organization_path }

      it { is_expected.to render_template(:edit) }
      it { expect(response).to be_successful }
      it 'initializing the given organization' do
        expect(assigns(:organization)).to be_a(Organization) &
                                          have_attributes(
                                            name: organization.name,
                                            email: organization.email,
                                            url: organization.url
                                          )
      end
    end

    describe "PATCH #update" do
      let(:update_param) { { organization: { name: "Thunder Pants" } } }
      subject { patch "/manage", params: update_param }

      it "should be redirect after update" do
        subject
        expect(response).to redirect_to(organization_path)
      end

      it "can update name" do
        expect { subject }.to change { organization.reload.name }.to "Thunder Pants"
      end

      context "when organization can not be updated" do
        let(:invalid_organization) { create(:organization, name: "Original Name") }
        let(:invalid_params) { { organization: { name: nil } } }

        subject { patch "/manage", params: invalid_params }

        it "renders edit template with an error message" do
          expect(subject).to render_template("edit")
          expect(flash[:error]).to be_present
        end
      end
    end

    describe "POST #promote_to_org_admin" do
      subject { post promote_to_org_admin_organization_path(user_id: user.id) }

      it "runs successfully" do
        subject
        expect(user.has_role?(Role::ORG_ADMIN, organization)).to eq(true)
        expect(response).to redirect_to(organization_path)
      end
    end

    describe "POST #demote_to_user" do
      let(:admin_user) do
        create(:organization_admin, organization: organization, name: "ADMIN USER")
      end
      subject { post demote_to_user_organization_path(user_id: admin_user.id) }

      it "runs correctly" do
        subject
        expect(admin_user.reload.has_role?(Role::ORG_ADMIN, admin_user.organization)).to be_falsey
        expect(response).to redirect_to(organization_path)
      end
    end

    describe "PUT #deactivate_user" do
      subject { put deactivate_user_organization_path(user_id: user.id) }

      it "redirect after update" do
        subject
        expect(response).to redirect_to(organization_path)
      end
      it "deactivates the user" do
        expect { subject }.to change { user.reload.discarded_at }.to be_present
      end
    end

    describe "PUT #reactivate_user" do
      subject { put reactivate_user_organization_path(user_id: user.id) }
      before { user.discard! }

      it "redirect after update" do
        subject
        expect(response).to redirect_to(organization_path)
      end
      it "reactivates the user" do
        expect { subject }.to change { user.reload.discarded_at }.to be_nil
      end
    end

    context "when attempting to access a different organization" do
      let(:other_organization) { create(:organization) }
      let(:other_organization_params) do
        { organization_name: other_organization.to_param }
      end

      describe "GET #show" do
        before { get organization_path(other_organization_params) }

        it "shows your own anyway" do
          expect(response.body).to include(organization.name)
        end
      end

      describe "GET #edit" do
        before { get edit_organization_path(other_organization_params) }

        it "shows your own anyway" do
          expect(response.body).to include(organization.name)
        end
      end

      describe "POST #promote_to_org_admin" do
        let(:other_user) { create(:user, organization: other_organization, name: "Wrong User") }

        subject { post promote_to_org_admin_organization_path(user_id: other_user.id) }

        it "redirects after update" do
          subject
          expect(response).to have_http_status(:not_found)
          expect(other_user.reload.has_role?(Role::ORG_ADMIN, organization)).to eq(false)
          expect(other_user.reload.has_role?(Role::ORG_ADMIN, other_organization)).to eq(false)
        end
      end
    end
  end

  context 'When signed in as a super admin' do
    before do
      sign_in(create(:super_admin, organization: organization))
    end

    describe "GET #show" do
      before { get admin_organizations_path(id: organization.id) }

      it { expect(response).to be_successful }

      it 'organization details' do
        expect(response.body).to include(organization.name)
        expect(response.body).to include(organization.email)
        expect(response.body).to include(organization.created_at.strftime("%Y-%m-%d"))
        expect(response.body).to include(organization.display_last_distribution_date)
      end
    end
  end
end
