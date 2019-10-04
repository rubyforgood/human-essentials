RSpec.describe Admin::OrganizationsController, type: :controller do
  let(:default_params) do
    { organization_id: @organization.id }
  end

  context "When logged in as a super admin" do
    before do
      sign_in(@super_admin)
    end

    describe "GET #new" do
      it "returns http success" do
        get :new
        expect(response).to be_successful
      end
    end

    describe "POST #create" do
      let(:valid_organization_params) { attributes_for(:organization, users_attributes: [attributes_for(:organization_admin)]) }

      context "with valid params" do
        it "redirects to #index" do
          post :create, params: { organization: valid_organization_params }

          expect(response).to redirect_to(admin_organizations_path)
        end
      end

      context "with invalid params" do
        let(:invalid_params) { valid_organization_params.merge(name: nil) }

        it "renders #create with an error message" do
          post :create, params: { organization: invalid_params }

          expect(subject).to render_template("new")
          expect(flash[:error]).to be_present
        end
      end
    end

    describe "GET #index" do
      it "returns http success" do
        get :index
        expect(response).to be_successful
      end
    end

    describe "PATCH #update" do
      let(:organization) { create(:organization, name: "Original Name") }
      subject do
        patch :update,
              params: default_params.merge(
                id: organization.id,
                organization: { name: updated_name }
              )
      end

      context "with a valid update" do
        let(:updated_name) { "Updated Name" }

        it "redirects to #index" do
          expect(subject).to have_http_status(:redirect)
          expect(subject).to redirect_to(admin_organizations_path)
        end
      end

      context "with an invalid update" do
        let(:updated_name) { nil }

        it "returns http success" do
          expect(subject).to be_successful
        end

        it "redirects to #edit with an error message" do
          expect(subject).to render_template("edit")
          expect(flash[:error]).to be_present
        end
      end
    end

    describe "DELETE #destroy" do
      let(:organization) { create(:organization) }

      context "with a valid organization id" do
        it "redirects to #index" do
          delete :destroy, params: { id: organization.id }
          expect(response).to redirect_to(admin_organizations_path)
        end
      end
    end

    describe "GET #edit" do
      let!(:organization) { create(:organization) }

      it "returns http success" do
        get :edit, params: { id: organization.id }
        expect(response).to be_successful
      end
    end

    describe "GET #show" do
      let!(:organization) { create(:organization) }

      it "returns http success" do
        get :show, params: { id: organization.id }
        expect(response).to be_successful
      end
    end
  end
=begin

    describe "GET #show" do
      it "returns http success" do
        get :show, params: { id: @organization.id }
        expect(response).to be_successful
      end
    end

    describe "GET #edit" do
      it "returns http success" do
        get :edit, params: { id: @organization.id }
        expect(response).to be_successful
      end
    end

    describe "PUT #update" do
      it "redirect" do
        put :update, params: { id: @organization.id, organization: { name: "Foo" } }
        expect(response).to be_redirect
      end
    end

    describe "DELETE #destroy" do
      it "redirects" do
        delete :destroy, params: { id: @organization.id }
        expect(response).to be_redirect
      end
    end
  end

  context "When logged in as a non-admin user" do
    before do
      sign_in(@user)
    end

    describe "GET #new" do
      it "redirects" do
        get :new
        expect(response).to be_redirect
      end
    end

    describe "POST #create" do
      it "redirects" do
        post :create, params: { organization: attributes_for(:organization) }
        expect(response).to be_redirect
      end
    end

    describe "GET #index" do
      it "redirects" do
        get :index
        expect(response).to be_redirect
      end
    end

    describe "GET #edit" do
      it "redirects" do
        get :edit, params: { id: @organization.id }
        expect(response).to be_redirect
      end
    end

    describe "PUT #update" do
      it "redirects" do
        put :update, params: { id: @organization.id, organization: { name: "Foo" } }
        expect(response).to be_redirect
      end
    end
  end
=end
end
