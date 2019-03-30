RSpec.feature "Canonical Item Admin" do
  context "While signed in as an Administrative User (super admin)" do
    before do
      sign_in(@super_admin)
    end

    let!(:url_prefix) {}
    context "when creating a new canonical item" do
      before do
        visit new_admin_canonical_item_path
      end

      let(:canonical_item_traits) { attributes_for(:canonical_item) }

      scenario "it succeeds when creating a new canonical item with good data" do
        fill_in "Name", with: canonical_item_traits[:name]
        fill_in "canonical_item_partner_key", with: canonical_item_traits[:partner_key]
        click_button "Save"

        expect(page.find(".alert")).to have_content "added"
      end

      scenario "it fails when creating a new canonical item with empty attributes" do
        click_button "Save"
        expect(page.find(".alert")).to have_content "ailed"
      end
    end

    context "when updating an existing canonical item" do
      before do
        visit edit_admin_canonical_item_path(canonical_item)
      end
      let(:canonical_item) { CanonicalItem.first }

      scenario "succeeds when changing the name" do
        fill_in "Name", with: canonical_item.name + " new"
        click_button "Save"
        expect(page.find(".alert")).to have_content "pdated"
      end

      scenario "fails when updating the name to empty" do
        fill_in "Name", with: ""
        click_button "Save"
        expect(page.find(".alert")).to have_content "ailed"
      end
    end

    scenario "viewing a listing of all Canonical Items that shows a summary of its sub-items" do
      canonical_item = CanonicalItem.first
      create_list(:item, 2, canonical_item: canonical_item)
      count = canonical_item.item_count
      visit admin_canonical_items_path
      expect(page).to have_content(canonical_item.name)
      within "table tbody tr#canonical-item-row-#{canonical_item.to_param} td:nth-child(2)" do
        expect(page).to have_content(count)
      end
    end

    scenario "viewing a single Canonical Item" do
      canonical_item = CanonicalItem.first
      visit admin_canonical_item_path(canonical_item)
      expect(page).to have_content(canonical_item.name)
    end
  end

  context "While signed in as an Administrative User with no organization (super admin no org)" do
    before do
      sign_in(@super_admin_no_org)
    end

    let!(:url_prefix) {}
    context "when creating a new canonical item" do
      before do
        visit new_admin_canonical_item_path
      end

      let(:canonical_item_traits) { attributes_for(:canonical_item) }

      scenario "it succeeds when creating a new canonical item with good data" do
        fill_in "Name", with: canonical_item_traits[:name]
        fill_in "canonical_item_partner_key", with: canonical_item_traits[:partner_key]
        click_button "Save"

        expect(page.find(".alert")).to have_content "added"
      end

      scenario "it fails when creating a new canonical item with empty attributes" do
        click_button "Save"
        expect(page.find(".alert")).to have_content "ailed"
      end
    end

    context "when updating an existing canonical item" do
      before do
        visit edit_admin_canonical_item_path(canonical_item)
      end
      let(:canonical_item) { CanonicalItem.first }

      scenario "succeeds when changing the name" do
        fill_in "Name", with: canonical_item.name + " new"
        click_button "Save"
        expect(page.find(".alert")).to have_content "pdated"
      end

      scenario "fails when updating the name to empty" do
        fill_in "Name", with: ""
        click_button "Save"
        expect(page.find(".alert")).to have_content "ailed"
      end
    end

    scenario "viewing a listing of all Canonical Items that shows a summary of its sub-items" do
      canonical_item = CanonicalItem.first
      create_list(:item, 2, canonical_item: canonical_item)
      count = canonical_item.item_count
      visit admin_canonical_items_path
      expect(page).to have_content(canonical_item.name)
      within "table tbody tr#canonical-item-row-#{canonical_item.to_param} td:nth-child(2)" do
        expect(page).to have_content(count)
      end
    end

    scenario "viewing a single Canonical Item" do
      canonical_item = CanonicalItem.first
      visit admin_canonical_item_path(canonical_item)
      expect(page).to have_content(canonical_item.name)
    end
  end

  context "While signed in as a normal user" do
    before do
      sign_in(@user)
    end
    scenario "A normal user can't see anything" do
      visit new_admin_canonical_item_path
      expect(page).to have_content("Access Denied")
      visit admin_canonical_items_path
      expect(page).to have_content("Access Denied")
      canonical_item = create(:canonical_item)
      visit admin_canonical_item_path(canonical_item)
      expect(page).to have_content("Access Denied")
      visit edit_admin_canonical_item_path(canonical_item)
      expect(page).to have_content("Access Denied")
    end
  end
end