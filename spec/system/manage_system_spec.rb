RSpec.describe "Organization Administration", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  subject { organization_path }

  context "while signed in as a normal user" do
    before do
      sign_in(user)
      visit subject
    end

    it "cannot see an edit link as a user" do
      expect(page).not_to have_link("Edit")
    end
  end

  context "while signed in as an organization admin" do
    before do
      sign_in(organization_admin)
      visit subject
    end

    it "can bail back to their own site as a user" do
      expect(page).to have_xpath("//a[@href='#{dashboard_path}']")
    end

    it "can edit the properties for an organization as an admin" do
      click_on "Edit"
      fill_in "Name", with: "Something else"
      click_button "Save"
      expect(page).to have_content("pdated your organization")
      expect(page).to have_content("Something else")
    end

    context "When looking at a single organization" do
      before do
        user = create(:user, email: "yet_another_user@website.com")
        user.add_role(Role::ORG_USER, organization)
        visit subject
      end

      it "can view details about an organization, including the users as an admin" do
        expect(page).to have_content(organization.email)
        expect(page).to have_content(organization.address)
        organization.users.each do |u|
          expect(page).to have_content(u.email)
        end
      end
    end
  end
end
