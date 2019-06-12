RSpec.feature "User sign in form", type: :feature do
  before do
    visit new_user_session_path
  end

  after do
    Capybara.reset_sessions!
  end

  context "when user are invalid" do
    scenario "shows invalid credentials alert" do
      fill_in "E-mail", with: 'invalid_username'
      fill_in "Password", with: 'invalid_password'
      click_button "Log in"

      expect(page).to have_content('Invalid Email or password.')
    end
  end

  context "when users are valid and has organization" do
    scenario "redirects to user's dashboard" do
      fill_in "E-mail", with: @user.email
      fill_in "Password", with: @user.password
      click_button "Log in"

      expect(page).to have_current_path(
        dashboard_path(organization_id: @user.organization)
      )
    end
  end

  context "when users are valid and do not has organization" do
    scenario "redirects to home " do
      user_no_org = create(:user_no_org)
      fill_in "E-mail", with: user_no_org.email
      fill_in "Password", with: user_no_org.password
      click_button "Log in"

      expect(page).to have_current_path(root_path)
    end
  end
end
