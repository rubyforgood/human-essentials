RSpec.feature "User sign in form", type: :feature do
  before do
    visit new_user_session_path
  end

  context "when users are invalid" do
    scenario "shows invalid credentials alert" do
      fill_in "Email", with: 'invalid_username'
      fill_in "Password", with: 'invalid_password'
      click_button "Log in"

      expect(page).to have_content('Invalid Email or password.')
    end
  end

  context "when users are valid and belong to an organization" do
    scenario "redirects to user's dashboard" do
      fill_in "Email", with: @user.email
      fill_in "Password", with: @user.password
      click_button "Log in"

      expect(page).to have_current_path(
        dashboard_path(organization_id: @user.organization)
      )
    end
  end

  context "when users are valid and don't belong to an organization" do
    scenario "redirects to home " do
      user_no_org = create(:user, organization: nil)
      fill_in "Email", with: user_no_org.email
      fill_in "Password", with: user_no_org.password
      click_button "Log in"

      expect(page).to have_current_path(root_path)
    end
  end
end
