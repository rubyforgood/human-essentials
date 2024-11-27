RSpec.describe "Creating a parner child", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:partner) { FactoryBot.create(:partner, organization: organization) }
  let(:partner_user) { partner.primary_user }
  let(:family) { create(:partners_family, guardian_first_name: "Main", guardian_last_name: "Family", partner: partner) }

  before do
    partner.update(status: :approved)
    login_as(partner_user)
    create(:item, name: "Item 1", organization: organization)
    create(:item, name: "Item 2", organization: organization)
  end

  describe "creating a child for a family" do
    it "creates a child with correct info" do
      visit new_partners_child_path(family_id: family.id)
      fill_in "First Name", with: "Child First Name"
      fill_in "Last Name", with: "Child Last Name"
      select "Other", from: "Race"
      fill_in "Agency Child ID", with: "01234"
      fill_in "Comments", with: "Some Comment"

      select2(page, "requestable-items-container", "Item 2")
      select2(page, "requestable-items-container", "Item 1")

      click_button "Create Child"

      expect(page).to have_text("Child was successfully created.")
      expect(page).to have_text("Child First Name")
      expect(page).to have_text("Child Last Name")
      expect(page).to have_text("01234")
      expect(page).to have_text("Some Comment")
      expect(page).to have_text("Item 1, Item 2")
    end
  end
end
