RSpec.describe "Admin Users Management", type: :system, js: true do
  context "While signed in as an Administrative User (super admin)" do
    before do
      sign_in(@super_admin)
    end

    it "creates an user" do
      visit admin_users_path(organization_id: @organization.id)
      click_link "Invite a new user"
      find('#user_organization_id option:last-of-type').select_option
      fill_in "user_name", with: "TestUser"
      fill_in "user_email", with: "testuser@example.com"
      fill_in "user_password", with: "password!"
      fill_in "user_password_confirmation", with: "password!"
      click_on "Save"

      expect(page.find(".alert")).to have_content "Created a new user!"
    end

    it "edits an existing user" do
      visit admin_users_path
      click_link "Edit", match: :first
      expect(page).to have_content("Update #{@organization_admin.name}")
      fill_in "user_name", with: "TestUser"
      fill_in "user_password", with: "123password!"
      fill_in "user_password_confirmation", with: "123password!"
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

    it "filters users by name" do
      User.delete_all
      user_a = create(:user, name: "Alex")
      user_b = create(:user, name: "Bob")
      user_c = create(:user, name: "Crystal")

      visit admin_users_path
      [user_a, user_b, user_c].each do |user|
        expect(page.find("table")).to have_content(user.name)
      end

      fill_in "filterrific_search_name", with: user_a.name
      [user_b, user_c].each do |user|
        expect(page.find("table")).not_to have_content(user.name)
      end
      expect(page.find("table")).to have_content(user_a.name)
    end
  end
end
