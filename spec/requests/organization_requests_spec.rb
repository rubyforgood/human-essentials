require "rails_helper"

RSpec.describe "Organizations", type: :request do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  context "While signed in as a normal user" do
    before do
      sign_in(@user)
    end

    describe "GET #show" do
      before { get organization_path(default_params) }

      it { expect(response).to be_successful }

      it 'load the current organization' do
        expect(assigns(:organization)).to have_attributes(
          name: @organization.name,
          email: @organization.email,
          url: @organization.url
        )
      end
    end

    describe "GET #edit" do
      before { get edit_organization_path(default_params) }

      it { expect(response).to redirect_to(dashboard_path) }
      it { expect(response).to have_error }
    end

    describe "PATCH #update" do
      let(:update_param) { { organization: { name: "Thunder Pants" } } }
      before do
        patch "/#{default_params[:organization_id]}/manage",
              params: default_params.merge(update_param)
      end

      it { expect(response).to redirect_to(dashboard_path) }
      it { expect(response).to have_error }
    end
  end

  context "While signed in as an organization admin" do
    before do
      sign_in(@organization_admin)
    end

    describe "GET #edit" do
      before { get edit_organization_path(default_params) }

      it { is_expected.to render_template(:edit) }
      it { expect(response).to be_successful }
      it 'initializing the given organization' do
        expect(assigns(:organization)).to be_a(Organization) &
                                          have_attributes(
                                            name: @organization.name,
                                            email: @organization.email,
                                            url: @organization.url
                                          )
      end
    end

    describe "PATCH #update" do
      let(:update_param) { { organization: { name: "Thunder Pants" } } }
      subject do
        patch "/#{default_params[:organization_id]}/manage",
              params: default_params.merge(update_param)
      end

      it "should be redirect after update" do
        subject
        expect(response).to redirect_to(organization_path)
      end
      it "can update name" do
        expect { subject }.to change { @organization.reload.name }.to "Thunder Pants"
      end

      context "when organization can not be updated" do
        before { allow(OrganizationUpdateService).to receive(:update).and_return(false) }

        it "redirects to #edit with an error message" do
          subject

          expect(subject).to render_template("edit")
          expect(flash[:error]).to be_present
        end
      end
    end

    describe "POST #promote_to_org_admin" do
      subject { post promote_to_org_admin_organization_path(default_params.merge(user_id: @user.id)) }

      it "promotes the user to organization admin" do
        subject
        expect(response).to redirect_to(organization_path)
      end
      it "change user" do
        expect { subject }.to change { @user.reload.kind }.to "admin"
      end
    end

    describe "POST #demote_to_user" do
      let(:admin_user) do
        create(:user, organization: @organization, name: "ADMIN USER")
      end
      subject { post demote_to_user_organization_path(default_params.merge(user_id: admin_user.id)) }

      it "redirect after update" do
        subject
        expect(response).to redirect_to(organization_path)
      end
      it "demotes the user to user" do
        subject
        expect(admin_user.reload.has_role?(Role::ORG_ADMIN, admin_user.organization)).to be_falsey
      end
    end

    describe "PUT #deactivate_user" do
      subject { put deactivate_user_organization_path(default_params.merge(user_id: @user.id)) }

      it "redirect after update" do
        subject
        expect(response).to redirect_to(organization_path)
      end
      it "deactivates the user" do
        expect { subject }.to change { @user.reload.discarded_at }.to be_present
      end
    end

    describe "PUT #reactivate_user" do
      subject { put reactivate_user_organization_path(default_params.merge(user_id: @user.id)) }
      before { @user.discard! }

      it "redirect after update" do
        subject
        expect(response).to redirect_to(organization_path)
      end
      it "reactivates the user" do
        expect { subject }.to change { @user.reload.discarded_at }.to be_nil
      end
    end

    context "when attempting to access a different organization" do
      let(:other_organization) { create(:organization) }
      let(:other_organization_params) do
        { organization_id: other_organization.to_param }
      end

      describe "GET #show" do
        before { get organization_path(other_organization_params) }

        it "redirects to dashboard" do
          expect(response).to redirect_to(dashboard_path)
        end
      end

      describe "GET #edit" do
        before { get edit_organization_path(other_organization_params) }

        it "redirects to dashboard" do
          expect(response).to redirect_to(dashboard_path)
        end
      end

      describe "POST #promote_to_org_admin" do
        let(:other_user) { create(:user, organization: other_organization) }

        subject { post promote_to_org_admin_organization_path(default_params.merge(user_id: other_user.id)) }

        it "redirect after update" do
          subject
          expect(response).to have_http_status(:not_found)
        end
        it "does not promote user" do
          expect { subject }.not_to change { other_user.reload.organization_admin }
        end
      end
    end
  end

  context 'When signed in as a super admin' do
    before do
      sign_in(@super_admin)
    end

    describe "POST #promote_to_org_admin" do
      subject { post promote_to_org_admin_organization_path(default_params.merge(user_id: @user.id)) }

      it "redirect after update" do
        subject
        expect(response).to redirect_to(admin_organization_path(@organization.id, default_params))
      end
      it "change user" do
        expect { subject }.to change { @user.reload.kind }.to "admin"
      end
    end

    describe "POST #demote_to_user" do
      let(:admin_user) do
        create(:user, organization: @organization, name: "ADMIN USER")
      end
      subject { post demote_to_user_organization_path(default_params.merge(user_id: admin_user.id)) }

      it "redirect after update" do
        subject
        expect(response).to redirect_to(admin_organization_path(@organization.id, default_params))
      end
      it "demotes the user to user" do
        subject
        expect(admin_user.reload.has_role?(Role::ORG_ADMIN, admin_user.organization)).to be_falsey
      end
    end

    describe "PUT #deactivate_user" do
      subject { put deactivate_user_organization_path(default_params.merge(user_id: @user.id)) }

      it "redirect after update" do
        subject
        expect(response).to redirect_to(admin_organization_path(@organization.id, default_params))
      end
      it "deactivates the user" do
        expect { subject }.to change { @user.reload.discarded_at }.to be_present
      end
    end

    describe "PUT #reactivate_user" do
      subject { put reactivate_user_organization_path(default_params.merge(user_id: @user.id)) }
      before { @user.discard! }

      it "redirect after update" do
        subject
        expect(response).to redirect_to(admin_organization_path(@organization.id, default_params))
      end
      it "reactivates the user" do
        expect { subject }.to change { @user.reload.discarded_at }.to be_nil
      end
    end
  end
end
