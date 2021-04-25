RSpec.describe "Family requests", type: :system, js: true do
  let(:partner) { FactoryBot.create(:partner) }
  let(:partner_user) { partner.primary_partner_user }
  let(:family) { create(:partners_family, guardian_last_name: "Morales", partner: partner.profile) }
  let(:other_family) { create(:partners_family, partner: partner.profile) }

  before do
    partner.profile.update(partner_status: :verified)
    login_as(partner_user, scope: :partner_user)
  end

  describe "for children with different items, from different families" do
    let!(:children) do
      [
        create(:partners_child, family: family),
        create(:partners_child, family: family, item_needed_diaperid: 2),
        create(:partners_child, family: family, item_needed_diaperid: 2),
        create(:partners_child, family: other_family, item_needed_diaperid: 2),
        create(:partners_child, family: other_family)
      ]
    end

    scenario "it creates family requests" do
      visit partners_requests_path
      click_link "Create New Family Essentials Request"
      find('input[type="submit"]').click
      expect(page).to have_text("Request Details")
      click_link "Your Previous Requests"
      expect(page).to have_text("Request History")
      expect(Partners::ChildItemRequest.pluck(:child_id)).to match_array(children.pluck(:id))
      expect(Partners::ItemRequest.pluck(:item_id)).to match_array(children.pluck(:item_needed_diaperid).uniq)
      expect(Partners::Request.last.for_families?).to eq(true)
    end
  end

  describe "filtering children" do
    scenario "user can see a list of children filtered by first_name" do
      create(:partners_child, first_name: "Zeno", family: family)
      create(:partners_child, first_name: "Arthur", family: family)

      visit partners_requests_path
      click_link "Create New Family Essentials Request"
      fill_in "Search By Child Name", with: "Arthur"
      expect(page).to have_text("Arthur")
      expect(page).to_not have_text("Zeno")
    end

    scenario "user can see a list of children filtered by guardian name" do
      create(:partners_child, first_name: "Zeno", family: family)
      create(:partners_child, first_name: "Arthur", family: family)
      create(:partners_child, first_name: "Louis", family: other_family)

      visit partners_requests_path
      click_link "Create New Family Essentials Request"
      expect(page).to have_css("table tbody tr", count: 3)
      fill_in "Search By Guardian Name", with: "Morales"
      expect(page).to have_text("Zeno")
      expect(page).to have_text("Arthur")
      expect(page).to_not have_text("Louis")
    end
  end
end

