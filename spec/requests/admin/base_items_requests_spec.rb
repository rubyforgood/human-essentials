RSpec.describe "Admin::BaseItems", type: :request do
  let(:organization) { create(:organization, :with_items) }
  let(:user) { create(:user, organization: organization) }
  let(:super_admin) { create(:super_admin, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  context "while signed in as a super admin" do
    before do
      sign_in(super_admin)
    end

    it "doesn't let you delete the Kit base item" do
      kit_base_item = KitCreateService.find_or_create_kit_base_item!
      delete admin_base_item_path(id: kit_base_item.id)
      expect(flash[:alert]).to include("You cannot delete the Kits base item")
      expect(response).to be_redirect
      expect(BaseItem.exists?(kit_base_item.id)).to be true
    end
  end

  context "When logged in as an organization admin" do
    before do
      sign_in(organization_admin)
    end

    describe "GET #index" do
      it "denies access and redirects" do
        get admin_base_items_path
        expect(flash[:error]).to eq("Access Denied.")
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end
end
