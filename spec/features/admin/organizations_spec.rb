RSpec.feature "Admin Organization Management" do
  context "While signed in as an Administrative User (super admin)" do
    before :each do
      sign_in(@super_admin)
    end

    scenario "creating a new organization" do
      allow(User).to receive(:invite!).and_return(true)
      visit new_admin_organization_path
      screenshot_and_open_image
      click_link "Add New Organization"
      org_params = attributes_for(:organization)
      fill_in "organization_name", with: org_params[:name]
      fill_in "organization_short_name", with: org_params[:short_name]
      fill_in "organization_url", with: org_params[:url]
      fill_in "organization_email", with: org_params[:email]
      fill_in "organization_street", with: "1234 Banana Drive"
      fill_in "organization_city", with: "Boston"
      select("MA", from: "organization_state")
      fill_in "organization_zipcode", with: "12345"

      admin_user_params = attributes_for(:organization_admin)
      fill_in "organization_users_attributes_0_name", with: admin_user_params[:name]
      fill_in "organization_users_attributes_0_email", with: admin_user_params[:email]
      fill_in "organization_users_attributes_0_password", with: "123password"
      fill_in "organization_users_attributes_0_password_confirmation", with: "123password"
      check "organization_users_attributes_0_organization_admin"

      click_on "Save"

      expect(page).to have_content("All Diaperbase Organizations")

      within("tr.#{org_params[:short_name]}") do
        first(:link, "View").click
      end

      expect(page).to have_content(org_params[:name])
      expect(page).to have_content("Banana")
      expect(page).to have_content("Boston")
      expect(page).to have_content("MA")
      expect(page).to have_content("12345")

      expect(page).to have_content(admin_user_params[:name])
      expect(page).to have_content(admin_user_params[:email])
      expect(page).to have_content("invited")
    end
  end
  context "While signd in as an Administrative User with no organization (super admin no org)" do
    before :each do
      sign_in(@super_admin_no_org)
    end

    scenario "creating a new organization" do
      allow(User).to receive(:invite!).and_return(true)
      visit new_admin_organization_path
      screenshot_and_open_image
      click_link "Add New Organization"
      org_params = attributes_for(:organization)
      fill_in "organization_name", with: org_params[:name]
      fill_in "organization_short_name", with: org_params[:short_name]
      fill_in "organization_url", with: org_params[:url]
      fill_in "organization_email", with: org_params[:email]
      fill_in "organization_street", with: "1234 Potato Drive"
      fill_in "organization_city", with: "New York"
      select("NY", from: "organization_state")
      fill_in "organization_zipcode", with: "54321"

      admin_user_params = attributes_for(:organization_admin)
      fill_in "organization_users_attributes_0_name", with: admin_user_params[:name]
      fill_in "organization_users_attributes_0_email", with: admin_user_params[:email]
      fill_in "organization_users_attributes_0_password", with: "543password"
      fill_in "organization_users_attributes_0_password_confirmation", with: "543password"
      check "organization_users_attributes_0_organization_admin"

      click_on "Save"

      expect(page).to have_content("All Diaperbase Organizations")

      within("tr.#{org_params[:short_name]}") do
        first(:link, "View").click
      end

      expect(page).to have_content(org_params[:name])
      expect(page).to have_content("Potato")
      expect(page).to have_content("New York")
      expect(page).to have_content("NY")
      expect(page).to have_content("54321")

      expect(page).to have_content(admin_user_params[:name])
      expect(page).to have_content(admin_user_params[:email])
      expect(page).to have_content("invited")
    end
  end
end