RSpec.feature "Canonical Item management", type: :feature do
  context "While signed in as an organizationl admin" do
    before do
      sign_in(@organization_admin)
    end

    let!(:url_prefix) {}
    scenario "Admin can create a new canonical item" do
      visit "/canonical_items/new"
      canonical_item_traits = attributes_for(:canonical_item)
      fill_in "Name", with: canonical_item_traits[:name]
      fill_in "Category", with: canonical_item_traits[:category]
      click_button "Create Canonical Item"

      expect(page.find(".alert")).to have_content "added"
    end

    scenario "Admin creates a new canonical item with empty attributes" do
      visit "/canonical_items/new"
      click_button "Create Canonical Item"

      expect(page.find(".alert")).to have_content "ailed"
    end

    scenario "Admin updates an existing canonical item" do
      canonical_item = CanonicalItem.first
      visit "/canonical_items/#{canonical_item.to_param}/edit"
      fill_in "Name", with: canonical_item.name + " new"
      click_button "Update Canonical Item"
      expect(page.find(".alert")).to have_content "pdated"
    end

    scenario "Admin updates an existing item with empty attributes" do
      canonical_item = CanonicalItem.first
      visit "/canonical_items/#{canonical_item.to_param}/edit"
      fill_in "Name", with: ""
      click_button "Update Canonical Item"
      expect(page.find(".alert")).to have_content "ailed"
    end

    scenario "Admin can see a listing of all Canonical Items that shows a summary of its sub-items" do
      canonical_item = CanonicalItem.first
      create_list(:item, 2, canonical_item: canonical_item)
      count = canonical_item.item_count
      visit "/canonical_items"
      expect(page).to have_content(canonical_item.name)
      within "table tbody tr#canonical-item-row-#{canonical_item.to_param} td:nth-child(3)" do
        expect(page).to have_content(count)
      end
    end

    scenario "Admin can view a single Canonical Item" do
      canonical_item = CanonicalItem.first
      visit "/canonical_items/#{canonical_item.to_param}"
      expect(page).to have_content(canonical_item.name)
    end
  end

  context "While signed in as a normal user" do
    before do
      sign_in(@user)
    end
    scenario "A normal user can't see anything" do
      visit "/canonical_items/new"
      expect(page).to have_content("Access Denied")
      visit "/canonical_items/index"
      expect(page).to have_content("Access Denied")
      canonical_item = create(:canonical_item)
      visit "/canonical_items/#{canonical_item.id}"
      expect(page).to have_content("Access Denied")
      visit "/canonical_items/#{canonical_item.id}/edit"
      expect(page).to have_content("Access Denied")
    end
  end
end
