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
        expect(flash[:error]).to be_present
      end
    end

    describe "PATCH #update" do
      subject { patch :update, params: default_params.merge(organization: { name: "Thunder Pants" }) }

      it "denies access" do
        expect(subject).to have_http_status(:redirect)
        expect(flash[:error]).to be_present
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
    end
  end
end
