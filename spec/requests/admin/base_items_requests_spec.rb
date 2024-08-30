RSpec.describe "Admin::BaseItems", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:super_admin) { create(:super_admin, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  context "while signed in as a super admin" do
    before do
      sign_in(super_admin)
    end

    it "doesn't let you delete the Kit base item" do
      kit_base_item = KitCreateService.FindOrCreateKitBaseItem!
      delete admin_base_item_path(id: kit_base_item.id)
      expect(flash[:alert]).to include("You cannot delete the Kits base item")
      expect(response).to be_redirect
      expect(BaseItem.exists?(kit_base_item.id)).to be true
    end
  end

  # TODO aren't organization_admins not allowed to view base items?
  # also, some of these tests are sending organization.id instead of BaseItem.id as args
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
