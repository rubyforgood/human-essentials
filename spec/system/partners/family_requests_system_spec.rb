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

    scenario "it creates family requests" do
      visit partners_requests_path
      find('a[aria-label="Create a request for a child or family"]').click

      within("table tbody tr", text: "Main Items1") do |row|
        expect(row).to have_css("td", text: "Main Family")
        expect(row).to have_css("td", text: "Main Items1")
        expect(row).to have_css("td", text: "Item 1, Item 2")
      end

      within("table tbody tr", text: "Main Items2") do |row|
        expect(row).to have_css("td", text: "Main Family")
        expect(row).to have_css("td", text: "Main Items2")
        expect(row).to have_css("td", text: "Item 2, Item 3")
      end

      within("table tbody tr", text: "Main No Items") do |row|
        expect(row).to have_css("td", text: "Main Family")
        expect(row).to have_css("td", text: "Main No Items")
        expect(row).to have_css("td", text: "N/A")
      end

      within("table tbody tr", text: "Other Items") do |row|
        expect(row).to have_css("td", text: "Other Family")
        expect(row).to have_css("td", text: "Other Items")
        expect(row).to have_css("td", text: "Item 1, Item 2")
      end

      within("table tbody tr", text: "Other No Items") do |row|
        expect(row).to have_css("td", text: "Other Family")
        expect(row).to have_css("td", text: "Other No Items")
        expect(row).to have_css("td", text: "N/A")
      end

      find('input[type="submit"]').click
      expect(page).to have_text("Request Details")
      click_link "Your Previous Requests"
      expect(page).to have_text("Request History")
    end
  end

  describe "filtering children" do
    scenario "user can see a list of children filtered by first_name" do
      create(:partners_child, first_name: "Zeno", family: family)
      create(:partners_child, first_name: "Arthur", family: family)

      visit partners_requests_path
      find('a[aria-label="Create a request for a child or family"]').click
      fill_in "Search By Child Name", with: "Arthur"
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
      fill_in "Search By Guardian Name", with: "Main Family"
      expect(page).to have_text("Zeno")
      expect(page).to have_text("Arthur")
      expect(page).to_not have_text("Louis")
    end
  end
end

