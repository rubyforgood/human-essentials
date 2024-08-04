RSpec.describe "Admin::BaseItems", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  # TODO: should this be testing something?
  context "while signed in as a super admin" do
    before do
      sign_in(@super_admin)
    end
  end

  context "When logged in as an organization admin" do
    before do
      sign_in(organization_admin)
    end

    describe "GET #new" do
      it "returns http success" do
        get new_admin_base_item_path
        expect(response).to have_http_status(:found)
      end
    end

    describe "POST #create" do
      it "redirects" do
        post admin_base_items_path(organization: attributes_for(:organization))
        expect(response).to be_redirect
      end
    end

    describe "GET #index" do
      it "returns http success" do
        get admin_base_items_path
        expect(response).to have_http_status(:found)
      end
    end

    describe "GET #show" do
      it "returns http success" do
        get admin_base_item_path(id: organization.id)
        expect(response).to have_http_status(:found)
      end
    end

    describe "GET #edit" do
      it "returns http success" do
        get edit_admin_base_item_path(id: organization.id)
        expect(response).to have_http_status(:found)
      end
    end

    describe "PUT #update" do
      it "redirect" do
        put admin_base_item_path(id: organization.id, organization: { name: "Foo" })
        expect(response).to be_redirect
      end
    end

    describe "DELETE #destroy" do
      it "redirects" do
        delete admin_base_item_path(id: organization.id)
        expect(response).to be_redirect
      end
    end
  end
end
