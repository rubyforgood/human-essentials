RSpec.describe "Admin Users Management", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }
  let(:super_admin) { create(:super_admin, organization: organization) }

  context "While signed in as an Administrative User (super admin)" do
    before do
      sign_in(super_admin)
    end

    it "creates an user" do
      visit admin_users_path
      click_link "Invite a new user"
      find('#user_organization_id option:last-of-type').select_option
      fill_in "user_name", with: "TestUser"
      fill_in "user_email", with: "testuser@example.com"
      click_on "Save"

      expect(page.find(".alert")).to have_content "Created a new user!"
    end

    it "edits an existing user" do
      create(:user, organization: organization, name: "AAlphabetically First User")

      visit admin_users_path
      click_link "Edit", match: :first
      expect(page).to have_content("Update AAlphabetically First User")

      fill_in "user_name", with: "TestUser"
      select(organization.name, from: 'user_organization_id')
      click_on "Save"

      expect(page.find(".alert")).to have_content "TestUser updated"

      # Check if the organization role has been updated
      tbody = find('#filterrific_results table tbody')
      first_row = tbody.find('tr', text: 'TestUser')
      expect(first_row).to have_text(organization.name)
    end

    it 'adds a role' do
      user = create(:user, name: 'User 123', organization: organization)
      create(:partner, name: 'Partner ABC', organization: organization)

      visit edit_admin_user_path(user)
      expect(page).to have_content('User 123')
      select "Partner", from: "resource_type"
      find("div.input-group:has(.select2-container)").click
      find('.select2-search__field', wait: 5).set("Partner ABC")
      find(:xpath,
        "//li[contains(@class, 'select2-results__option') and contains(., 'Partner ABC')]",
        wait: 5).click
      click_on 'Add Role'

      expect(page.find('.alert')).to have_content('Role added')
    end

    it "filters users by name" do
      create(:user, name: "UserA", organization: organization)
      create(:user, name: "UserB", organization: organization)
      create(:user, name: "UserC", organization: organization)

      user_names = ["UserA", "UserB", "UserC"]

      visit admin_users_path

      user_names.each do |name|
        expect(page.find("table")).to have_content(name)
      end

      fill_in "filterrific_search_name", with: user_names.first

      user_names[1..].each do |name|
        expect(page.find("table")).not_to have_content(name)
      end

      expect(page.find("table")).to have_content(user_names.first)
    end

    it "filters users by email" do
      user_email = organization_admin.email

      visit admin_users_path
      fill_in "filterrific_search_email", with: user_email
      page.find("table", text: user_email) # Wait for search
      expect(page).to have_element("table", text: user_email)
    end

    context "with an organization admin role" do
      before do
        super_admin.remove_role(Role::ORG_USER, organization)
        super_admin.add_role(Role::ORG_ADMIN, organization)
      end

      it "can see link to switch to the other role" do
        visit admin_dashboard_path
        click_link "Administrative User", match: :first
        expect(page).to have_content "Switch to: #{organization.name}"
      end
    end

    context "without another role" do
      before do
        super_admin.remove_role(Role::ORG_USER, organization)
      end

      it "does not see link to switch to another role" do
        visit admin_dashboard_path
        click_link "Administrative User", match: :first
        expect(page).not_to have_content "Switch to: #{organization.name}"
      end
    end
  end
end
