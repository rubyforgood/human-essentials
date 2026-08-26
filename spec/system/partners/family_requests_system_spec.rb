RSpec.describe "Family requests", type: :system, js: true do
  let(:partner) { FactoryBot.create(:partner) }
  let(:partner_user) { partner.primary_user }
  let(:family) { create(:partners_family, guardian_first_name: "Main", guardian_last_name: "Family", partner: partner) }
  let(:other_family) { create(:partners_family, partner: partner, guardian_first_name: "Other", guardian_last_name: "Family") }

  before do
    partner.update(status: :approved)
    login_as(partner_user)
  end

  describe "for children with different items, from different families" do
    let(:item1) { create(:item, name: "Item 1") }
    let(:item2) { create(:item, name: "Item 2") }
    let(:item3) { create(:item, name: "Item 3") }

    before do
      create(:partners_child, family: family, first_name: "Main", last_name: "No Items", requested_item_ids: nil)
      create(:partners_child, family: family, first_name: "Main", last_name: "Items1", requested_item_ids: [item1.id, item2.id])
      create(:partners_child, family: family, first_name: "Main", last_name: "Items2", requested_item_ids: [item2.id, item3.id])
      create(:partners_child, first_name: "Other", last_name: "Items", family: other_family, requested_item_ids: [item1.id, item2.id])
      create(:partners_child, first_name: "Other", last_name: "No Items", family: other_family, requested_item_ids: nil)
    end

    # Every one of these used to be labelled "Include This Child?", so a screen reader announced the
    # same name for all of them with nothing to tell them apart -- the defect row actions had, and
    # the same fix: name the control after its row.
    scenario "each checkbox names the child it includes" do
      visit new_partners_family_request_path

      names = page.all("input[type=checkbox][id^='child-']", visible: :all).map do |box|
        page.find("label[for='#{box[:id]}']", visible: :all).text(:all).strip
      end

      expect(names).to be_present
      expect(names).to all(start_with("Include "))
      expect(names.uniq.length).to eq(names.length)
      expect(names).to include("Include Main Items1")
    end

    scenario "it creates family requests" do
      visit partners_requests_path
      find('a[aria-label="Create a request for a child or family"]').click

      within("table tbody tr", text: "Main Items1") do |row|
        expect(row).to have_css("td", text: "Main Family")
        expect(row).to have_css("td", text: "Main Items1")
        expect(row).to have_css("td", text: /Item 1, Item 2|Item 2, Item 1/) # order of items requested not guaranteed
      end

      within("table tbody tr", text: "Main Items2") do |row|
        expect(row).to have_css("td", text: "Main Family")
        expect(row).to have_css("td", text: "Main Items2")
        expect(row).to have_css("td", text: /Item 2, Item 3|Item 3, Item 2/) # order of items requested not guaranteed
      end

      within("table tbody tr", text: "Main No Items") do |row|
        expect(row).to have_css("td", text: "Main Family")
        expect(row).to have_css("td", text: "Main No Items")
        expect(row).to have_css("td", text: "N/A")
      end

      within("table tbody tr", text: "Other Items") do |row|
        expect(row).to have_css("td", text: "Other Family")
        expect(row).to have_css("td", text: "Other Items")
        expect(row).to have_css("td", text: /Item 1, Item 2|Item 2, Item 1/) # order of items requested not guaranteed
      end

      within("table tbody tr", text: "Other No Items") do |row|
        expect(row).to have_css("td", text: "Other Family")
        expect(row).to have_css("td", text: "Other No Items")
        expect(row).to have_css("td", text: "N/A")
      end

      find('input[type="submit"]').click
      expect(page).to have_selector("#partnerFamilyRequestConfirmationModal")
      within "#partnerFamilyRequestConfirmationModal" do
        click_button "Yes, it's correct"
      end

      expect(page).to have_text("Request details")
      # The bottom-of-page link was replaced by the page header's back link.
      click_link "Back to requests"
      expect(page).to have_text("Request history")
    end

    # Issue #4644
    it "disables confirmation and modal close buttons after clicking confirm" do
      visit partners_requests_path
      find('a[aria-label="Create a request for a child or family"]').click
      click_button("Submit essentials request")

      # Disable form submission so form doesn't immediately submit and we can check button state
      page.execute_script("$(\"form[action='/partners/family_requests']\").attr('action', 'javascript: void(0);');")

      click_button(id: "modalYes")

      expect(page).to have_button(id: "modalYes", visible: false, disabled: true)
      expect(page).to have_button(id: "modalNo", visible: false, disabled: true)
      expect(page).to have_button(id: "modalClose", visible: false, disabled: true)
    end
  end

  describe "filtering children" do
    scenario "user can see a list of children filtered by first_name" do
      create(:partners_child, first_name: "Zeno", family: family)
      create(:partners_child, first_name: "Arthur", family: family)

      visit partners_requests_path
      find('a[aria-label="Create a request for a child or family"]').click
      fill_in "Search by child name", with: "Arthur"
      expect(page).to have_text("Arthur")
      expect(page).to_not have_text("Zeno")
    end

    scenario "user can see a list of children filtered by guardian name" do
      create(:partners_child, first_name: "Zeno", family: family)
      create(:partners_child, first_name: "Arthur", family: family)
      create(:partners_child, first_name: "Louis", family: other_family)

      visit partners_requests_path
      find('a[aria-label="Create a request for a child or family"]').click
      expect(page).to have_css("table tbody tr", count: 3)
      fill_in "Search by guardian name", with: "Main Family"
      expect(page).to have_text("Zeno")
      expect(page).to have_text("Arthur")
      expect(page).to_not have_text("Louis")
    end
  end
end
