RSpec.describe "ItemCategories", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before do
    sign_in(user)
  end

  let(:valid_attributes) {
    {
      name: "Item Category",
      description: "Test description"
    }
  }

  let(:invalid_attributes) {
    {
      name: "",
      description: nil
    }
  }

  describe "GET #show" do
    let!(:item_category) { create(:item_category, organization: organization) }

    it "renders a successful response" do
      get item_category_url(id: item_category.id)
      expect(response).to render_template(:show)
    end
  end

  describe "GET #new" do
    it "renders a successful response" do
      get new_item_category_url
      expect(response).to render_template(:new)
    end
  end

  describe "GET #edit" do
    let!(:item_category) { create(:item_category, organization: organization) }

    it "renders a successful response" do
      get edit_item_category_url(id: item_category.id)
      expect(response).to render_template(:edit)
    end
  end

  describe "POST #create" do
    context "with valid parameters" do
      it "creates a new ItemCategory then redirects" do
        expect {
          post item_categories_url(item_category: valid_attributes)
        }.to change(ItemCategory, :count).by(1)
        expect(response).to redirect_to(items_path)
        expect(ItemCategory.last.organization).to eq(organization)
      end
    end

    context "with invalid parameters" do
      it "does not create a new ItemCategory" do
        expect {
          post item_categories_url(item_category: invalid_attributes)
        }.to change(ItemCategory, :count).by(0)
        expect(response).to render_template(:new)
      end
    end
  end

  describe "PUT #update" do
    let!(:item_category) { create(:item_category, organization: organization) }

    context "with valid parameters" do
      let(:new_attributes) {
        {
          name: "New Category",
          description: "New description"
        }
      }

      it "updates the ItemCategory and redirects" do
        put item_category_url(id: item_category.id, item_category: new_attributes)
        item_category.reload
        expect(item_category.name).to eq("New Category")
        expect(item_category.description).to eq("New description")
        expect(response).to redirect_to(item_category_path(item_category))
      end
    end

    context "with invalid parameters" do
      it "does not render a successful response" do
        put item_category_url(id: item_category.id, item_category: invalid_attributes)
        expect(response).to render_template(:edit)
      end
    end
  end
end
