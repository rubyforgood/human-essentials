RSpec.describe "Base Item Admin", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:super_admin) { create(:super_admin, organization: organization) }
  let(:super_admin_no_org) { create(:super_admin, organization: nil) }
  let(:base_item) { create(:base_item) }

  context "While signed in as an Administrative User (super admin)" do
    before do
      sign_in(super_admin)
    end

    let!(:url_prefix) {}
    context "when creating a new base item" do
      before do
        visit new_admin_base_item_path
      end

      let(:base_item_traits) { attributes_for(:base_item) }

      it "should succeed when creating a new base item with good data" do
        fill_in "Name", with: base_item_traits[:name]
        fill_in "base_item_partner_key", with: base_item_traits[:partner_key]
        click_button "Save"

        expect(page.find(".alert")).to have_content "added"
      end

      it "should fail when creating a new base item with empty attributes" do
        click_button "Save"
        expect(page.find(".alert")).to have_content "ailed"
      end
    end

    context "when updating an existing base item" do
      before do
        visit edit_admin_base_item_path(base_item)
      end

      it "should succeed when changing the name" do
        fill_in "Name", with: base_item.name + " new"
        click_button "Save"
        expect(page.find(".alert")).to have_content "pdated"
      end

      it "should fail when updating the name to empty" do
        fill_in "Name", with: ""
        click_button "Save"
        expect(page.find(".alert")).to have_content "ailed"
      end
    end

    it "can view a listing of all Base Items that shows a summary of its sub-items" do
      create_list(:item, 2, base_item: base_item, organization: organization)
      count = base_item.item_count
      visit admin_base_items_path
      expect(page).to have_content(base_item.name)
      within "table tbody tr#base-item-row-#{base_item.to_param} td:nth-child(2)" do
        expect(page).to have_content(count)
      end
    end

    it "can view a single Base Item" do
      visit admin_base_item_path(base_item)
      expect(page).to have_content(base_item.name)
    end
  end

  context "While signed in as an Administrative User with no organization (super admin no org)" do
    before do
      sign_in(super_admin_no_org)
    end

    let!(:url_prefix) {}
    context "when creating a new base item" do
      before do
        visit new_admin_base_item_path
      end

      let(:base_item_traits) { attributes_for(:base_item) }

      it "should succeed when creating a new base item with good data" do
        fill_in "Name", with: base_item_traits[:name]
        fill_in "base_item_partner_key", with: base_item_traits[:partner_key]
        click_button "Save"

        expect(page.find(".alert")).to have_content "added"
      end

      it "should fail when creating a new base item with empty attributes" do
        click_button "Save"
        expect(page.find(".alert")).to have_content "ailed"
      end
    end

    context "when updating an existing base item" do
      before do
        visit edit_admin_base_item_path(base_item)
      end

      it "should succeed when changing the name" do
        fill_in "Name", with: base_item.name + " new"
        click_button "Save"
        expect(page.find(".alert")).to have_content "pdated"
      end

      it "should fail when updating the name to empty" do
        fill_in "Name", with: ""
        click_button "Save"
        expect(page.find(".alert")).to have_content "ailed"
      end
    end

    it "can view a listing of all Base Items that shows a summary of its sub-items" do
      create_list(:item, 2, base_item: base_item, organization: organization)
      count = base_item.item_count
      visit admin_base_items_path
      expect(page).to have_content(base_item.name)
      within "table tbody tr#base-item-row-#{base_item.to_param} td:nth-child(2)" do
        expect(page).to have_content(count)
      end
    end

    it "can view a single Base Item" do
      visit admin_base_item_path(base_item)
      expect(page).to have_content(base_item.name)
    end
  end

  context "While signed in as a normal user" do
    before do
      sign_in(user)
    end
    it "should have a normal user not see anything" do
      visit new_admin_base_item_path
      expect(page).to have_content("Access Denied")

      visit admin_base_items_path
      expect(page).to have_content("Access Denied")

      visit admin_base_item_path(base_item)
      expect(page).to have_content("Access Denied")

      visit edit_admin_base_item_path(base_item)
      expect(page).to have_content("Access Denied")
    end
  end
end
