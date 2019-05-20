RSpec.describe "Admin Users Management", type: :system, js: true do
  context "While signed in as an Administrative User (super admin)" do
    before :each do
      sign_in(@super_admin)
    end

    it "editing an existing user" do
      visit admin_users_path
      click_link "Edit", match: :first
      expect(page).to have_content("Edit user #{@organization_admin.name}")
      fill_in "user_name", with: "TestUser"
      fill_in "user_password", with: "123password"
      fill_in "user_password_confirmation", with: "123password"
      click_on "Save"
      expect(page.find(".alert")).to have_content "TestUser updated"
    end
  end
end
