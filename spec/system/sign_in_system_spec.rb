RSpec.describe "User sign-in handling", type: :system, js: true do
  subject { new_user_session_path }

  before do
    visit subject
  end

  context "when users are invalid" do
    it "shows invalid credentials alert" do
      fill_in "Email", with: 'invalid_username'
      fill_in "Password", with: 'invalid_password'
      click_button "Log in"

      expect(page).to have_content('Invalid Email or password.')
    end
  end

  context "when users are valid and belong to an organization" do
    it "redirects to user's dashboard" do
      fill_in "Email", with: @user.email
      fill_in "Password", with: DEFAULT_USER_PASSWORD
      click_button "Log in"

      expect(page).to have_current_path(
        dashboard_path(organization_id: @user.organization)
      )
    end
  end

  context 'when a partner user logs in' do
    it 'redirects to the partner page' do
      partner = create(:partner)
      partner_user = create(:partners_user, partner: partner)
      fill_in "Email", with: partner_user.email
      fill_in "user_password", with: partner_user.password
      click_button "Log in"

      expect(page).to have_current_path(partners_dashboard_path)
    end
  end

  context "when users are valid and don't belong to an organization" do
    it "redirects to home " do
      user_no_org = create(:user, organization: nil)
      fill_in "Email", with: user_no_org.email
      fill_in "Password", with: user_no_org.password
      click_button "Log in"

      expect(page).to have_current_path(root_path)
    end
  end
end
