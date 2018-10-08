RSpec.feature "Organization Administration", type: :feature do
  subject { "/#{@organization.to_param}/organization" }
  context "while signed in as a normal user" do
    before do
      sign_in(@user)
      visit subject
    end

    scenario "the user does not see an edit link" do
      expect(page).not_to have_link("Edit")
    end
  end
  context "while signed in as an organization admin" do
    before do
      sign_in(@organization_admin)
      visit subject
    end

    scenario "the user can bail back to their own site" do
      expect(page).to have_xpath("//a[@href='#{dashboard_path(organization_id: @organization.to_param)}']")
    end

    scenario "An admin can edit the properties for an organization" do
      click_on "Edit"
      fill_in "Name", with: "Something else"
      click_button "Update"
      expect(page).to have_content("pdated your organization")
      expect(page).to have_content("Something else")
    end

    context "When looking at a single organization" do
      before do
        @organization.users << create(:user, email: "yet_another_user@website.com")
        visit subject
      end
      scenario "Admin can view details about an organization, including the users" do
        expect(page).to have_content(@organization.email)
        expect(page).to have_content(@organization.address)
        @organization.users.each do |u|
          expect(page).to have_content(u.email)
        end
      end
    end
  end
end
