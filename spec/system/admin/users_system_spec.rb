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
      new_user = User.create!(name: "Willow", email: "email@email.com", password: "blahblah!")
      user_names = User.all.pluck(:name)

      visit admin_users_path
      user_names.each do |name|
        expect(page).to have_content(name)
      end

      user_names.delete("Willow")

      fill_in "filterrific_search_name", with: new_user.name
      user_names.each do |name|
        expect(page).not_to have_content(name)
      end
      expect(page).to have_content(new_user.name)
    end
  end
end
