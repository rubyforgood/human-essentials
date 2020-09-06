RSpec.describe OrganizationsController, type: :controller do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  context "While signed in as a normal user" do
    before do
      sign_in(@user)
    end

    describe "GET #show" do
      subject { get :show, params: default_params }

      it "is successful" do
        expect(subject).to be_successful
      end
    end

    describe "GET #edit" do
      subject { get :edit, params: default_params }

      it "denies access and redirects with an error" do
        expect(subject).to have_http_status(:redirect)
        expect(subject).to have_error
      end
    end

    describe "PATCH #update" do
      subject { patch :update, params: default_params.merge(organization: { name: "Thunder Pants" }) }

      it "denies access" do
        expect(subject).to have_http_status(:redirect)
        expect(subject).to have_error
      end
    end
  end

  context "While signed in as an organization admin" do
    before do
      sign_in(@organization_admin)
    end
    describe "GET #edit" do
      subject { get :edit, params: default_params }

      it "is successful" do
        expect(subject).to be_successful
      end
    end

    describe "PATCH #update" do
      subject { patch :update, params: default_params.merge(organization: { name: "Thunder Pants" }) }

      it "can update name" do
        expect(subject).to have_http_status(:redirect)

        @organization.reload
        expect(@organization.name).to eq "Thunder Pants"
      end
    end

    describe "POST #promote_to_org_admin" do
      subject { post :promote_to_org_admin, params: default_params.merge(user_id: @user.id) }

      it "promotes the user to organization admin" do
        expect(subject).to have_http_status(:redirect)

        @user.reload
        expect(@user.kind).to eq("admin")
      end
    end

    describe "POST #demote_to_user" do
      let(:admin_user) do
        create(:user, organization: @organization, name: "ADMIN USER")
      end

      subject { post :demote_to_user, params: default_params.merge(user_id: admin_user.id) }

      it "demotes the user to user" do
        expect(subject).to have_http_status(:redirect)

        admin_user.reload
        expect(admin_user.kind).to eq("normal")
      end
    end

    describe "POST #deactivate_user" do
      subject { post :deactivate_user, params: default_params.merge(user_id: @user.id) }

      it "deactivates the user" do
        expect(subject).to have_http_status(:redirect)

        @user.reload
        expect(@user.discarded_at).to be_present
      end
    end

    describe "POST #reactivate_user" do
      subject { post :reactivate_user, params: default_params.merge(user_id: @user.id) }

      it "reactivates the user" do
        @user.discard!
        expect(subject).to have_http_status(:redirect)

        @user.reload
        expect(@user.discarded_at).to be_nil
      end
    end

    context "when attempting to access a different organization" do
      let(:other_organization) { create(:organization) }
      let(:other_organization_params) do
        { organization_id: other_organization.to_param }
      end

      describe "GET #show" do
        subject { get :show, params: other_organization_params }

        it "redirects to dashboard" do
          expect(subject).to redirect_to(dashboard_path)
        end
      end

      describe "GET #edit" do
        subject { get :edit, params: other_organization_params }

        it "redirects to dashboard" do
          expect(subject).to redirect_to(dashboard_path)
        end
      end

      describe "POST #promote_to_org_admin" do
        let(:other_user) { create(:user, organization: other_organization) }

        subject { post :promote_to_org_admin, params: default_params.merge(user_id: other_user.id) }

        it "does not promote user" do
          expect(subject).to have_http_status(:not_found)

          other_user.reload
          expect(other_user.kind).to eq("normal")
        end
      end
    end
  end
end
