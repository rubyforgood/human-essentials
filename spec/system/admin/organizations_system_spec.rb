RSpec.describe "Admin Organization Management", type: :system, js: true do
  context "While signed in as an Administrative User (super admin)" do
    before :each do
      sign_in(@super_admin)
    end

    it "creates a new organization" do
      allow(User).to receive(:invite!).and_return(true)
      visit new_admin_organization_path
      org_params = attributes_for(:organization)
      fill_in "organization_name", with: org_params[:name]
      fill_in "organization_short_name", with: org_params[:short_name]
      fill_in "organization_url", with: org_params[:url]
      fill_in "organization_email", with: org_params[:email]
      fill_in "organization_street", with: "1500 Remount Road"
      fill_in "organization_city", with: "Front Royal"
      select("VA", from: "organization_state")
      fill_in "organization_zipcode", with: "22630"

      admin_user_params = attributes_for(:organization_admin)
      fill_in "organization_users_attributes_0_name", with: admin_user_params[:name]
      fill_in "organization_users_attributes_0_email", with: admin_user_params[:email]
      check "organization_users_attributes_0_organization_admin"

      click_on "Save"

      expect(page).to have_content("All Diaperbase Organizations")

      within("tr.#{org_params[:short_name]}") do
        first(:link, "View").click
      end

      expect(page).to have_content(org_params[:name])
      expect(page).to have_content("Remount")
      expect(page).to have_content("Front Royal")
      expect(page).to have_content("VA")
      expect(page).to have_content("22630")

      expect(page).to have_content(admin_user_params[:name])
      expect(page).to have_content(admin_user_params[:email])
      expect(page).to have_content("invited")
    end
  end
  context "While signed in as an Administrative User with no organization (super admin no org)" do
    before :each do
      sign_in(@super_admin_no_org)
    end

    it "creates a new organization" do
      allow(User).to receive(:invite!).and_return(true)
      visit new_admin_organization_path
      org_params = attributes_for(:organization)
      fill_in "organization_name", with: org_params[:name]
      fill_in "organization_short_name", with: org_params[:short_name]
      fill_in "organization_url", with: org_params[:url]
      fill_in "organization_email", with: org_params[:email]
      fill_in "organization_street", with: "1500 Remount Road"
      fill_in "organization_city", with: "Front Royal"
      select("VA", from: "organization_state")
      fill_in "organization_zipcode", with: "22630"

      admin_user_params = attributes_for(:organization_admin)
      fill_in "organization_users_attributes_0_name", with: admin_user_params[:name]
      fill_in "organization_users_attributes_0_email", with: admin_user_params[:email]
      check "organization_users_attributes_0_organization_admin"

      click_on "Save"

      expect(page).to have_content("All Diaperbase Organizations")

      within("tr.#{org_params[:short_name]}") do
        first(:link, "View").click
      end

      expect(page).to have_content(org_params[:name])
      expect(page).to have_content("Remount")
      expect(page).to have_content("Front Royal")
      expect(page).to have_content("VA")
      expect(page).to have_content("22630")
      expect(page).to have_content(admin_user_params[:name])
      expect(page).to have_content(admin_user_params[:email])
      expect(page).to have_content("invited")
    end
  end
end
