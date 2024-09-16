RSpec.describe "Organization management", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  include ActionView::RecordIdentifier

  context "while signed in as an organization admin" do
    before do
      sign_in(organization_admin)
    end

    it "can add a new user to an organization" do
      allow(User).to receive(:invite!).and_return(true)
      visit organization_path
      click_on "Invite User to this Organization"
      within "#addUserModal" do
        fill_in "email", with: "some_new_user@website.com"
        click_on "Invite User"
      end
      expect(page).to have_content("invited to organization")
    end

    it "can remove a user from the organization" do
      user = create(:user, name: "User to be deactivated", organization: organization)
      visit organization_path
      accept_confirm do
        click_button dom_id(user, "dropdownMenu")
        click_link "Remove User"
      end

      expect(page).to have_content("User has been removed!")
      expect(user.has_role?(Role::ORG_USER)).to be false
    end
  end
end
