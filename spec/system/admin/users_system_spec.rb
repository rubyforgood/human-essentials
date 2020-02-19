RSpec.describe "Admin Users Management", type: :system, js: true do
  context "While signed in as an Administrative User (super admin)" do
    before do
      sign_in(@super_admin)
    end

    it "creates an user" do
      visit admin_users_path
      click_link "Invite a new user"
      find('#user_organization_id option:first-of-type').select_option
      fill_in "user_name", with: "TestUser"
      fill_in "user_email", with: "testuser@example.com"
      fill_in "user_password", with: "password"
      fill_in "user_password_confirmation", with: "password"
      click_on "Save"

      expect(page.find(".alert")).to have_content "Created a new user!"
    end

    it "edits an existing user" do
      visit admin_users_path
      click_link "Edit", match: :first
      expect(page).to have_content("Update #{@organization_admin.name}")
      fill_in "user_name", with: "TestUser"
      fill_in "user_password", with: "123password"
      fill_in "user_password_confirmation", with: "123password"
      click_on "Save"

      expect(page.find(".alert")).to have_content "TestUser updated"
    end

    it "deletes an existing user" do
      visit admin_users_path
      page.accept_confirm do
        click_link "Delete", match: :first
      end

      expect(page.find(".alert")).to have_content "Deleted that user"
    end
  end
end
