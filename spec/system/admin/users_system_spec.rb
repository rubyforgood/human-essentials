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
      find('select#resource_type option:first-of-type').select_option
      # The resource_id select input has its options generated dynamically by
      # the double_select_controller using select2 so we need to open the dropdown
      find("label", text: "Resource").sibling(".input-group").click
      find('li[role="option"]', text: organization.name).click
      fill_in "user_name", with: "TestUser"
      fill_in "user_email", with: "testuser@example.com"
      click_on "Save"

      expect(page.find(".alert")).to have_content "Created a new user!"
    end

    it "creates a super admin user without specifying a resource" do
      visit new_admin_user_path
      find('select#resource_type option', text: "Super admin").select_option
      fill_in "user_name", with: "TestUser"
      fill_in "user_email", with: "testuser@example.com"
      click_on "Save"

      expect(page.find(".alert")).to have_content "Created a new user!"
    end

    it "complains if resource wasn't specified but was needed for the chosen role" do
      visit new_admin_user_path
      find('select#resource_type option', exact_text: "Organization").select_option
      fill_in "user_name", with: "TestUser"
      fill_in "user_email", with: "testuser@example.com"
      click_on "Save"

      expect(page.find(".error")).to have_content "Failed to create user: Please select an associated resource for the role."
    end

    it "hides the resource dropdown if super admin role is selected" do
      visit new_admin_user_path
      expect(page).to have_content("Resource")
      expect(page).to have_css(".select2")
      find('select#resource_type option', text: "Super admin").select_option
      expect(page).to_not have_content("Resource")
      expect(page).to_not have_css(".select2")
    end

    it "edits an existing user" do
      create(:user, organization: organization, name: "AAlphabetically First User")

      visit admin_users_path
      click_link "Edit", match: :first
      expect(page).to have_content("Update AAlphabetically First User")

      fill_in "user_name", with: "TestUser"
      click_on "Save"

      # Check if redirected to index page with successful flash message
      expect(page).to have_current_path(admin_users_path)
      expect(page).to have_css(".alert", text: "TestUser updated")

      # Check if user name has changed to TestUser
      users_table = find('#filterrific_results table tbody')
      expect(users_table).to have_text("TestUser")
    end

    shared_examples "add role check" do |user_factory|
      let!(:user_to_modify) { create(user_factory, name: "User to modify", organization: organization) }

      it "adds a role", :aggregate_failures do
        create(:partner, name: 'Partner ABC', organization: organization)
        visit edit_admin_user_path(user_to_modify)
        expect(page).to have_content('User to modify')
        select "Partner", from: "resource_type"
        find("div.input-group:has(.select2-container)").click
        find("li.select2-results__option", text: "Partner ABC").click
        click_on 'Add Role'

        expect(page.find('.alert')).to have_content('Role added')
      end
    end

    include_examples "add role check", :user
    context 'modifying another super admin' do
      include_examples "add role check", :super_admin
    end

    shared_examples "remove role check" do |user_factory|
      let!(:user_to_modify) { create(user_factory, name: "User to modify", organization: organization) }

      it "removes a role", :aggregate_failures do
        visit edit_admin_user_path(user_to_modify)
        expect(page).to have_content('User to modify')
        accept_confirm do
          click_on 'Delete', match: :first # For users that have multiple roles
        end
        expect(page.find('.alert')).to have_content('Role removed!')
      end
    end

    include_examples "remove role check", :user
    context 'modifying another super admin' do
      include_examples "remove role check", :super_admin
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

  describe "Resourse Dropdown List: Validate Order" do
    before do
      sign_in(super_admin)
    end

    it "Should sort display resource in human alphabetical order" do
      FactoryBot.create(:organization, id: 2, name: "Pawnee")
      FactoryBot.create(:organization, id: 3, name: "SF Diaper")
      FactoryBot.create(:organization, id: 4, name: "Second City")

      # params
      # - resource_type - Organization, Resource
      # - q - query string
      # visit admin_users_resource_ids_path # (name: "Organization", q: "")

      visit "/admin/users/resource_ids?resource_type=org_admin"
      expect(page).to have_content("{\"id\":2,\"text\":\"Pawnee\"},{\"id\":4,\"text\":\"Second City\"},{\"id\":3,\"text\":\"SF Diaper\"}")
    end
  end
end
