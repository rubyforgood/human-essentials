RSpec.describe "User sign-in handling", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

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
      fill_in "Email", with: user.email
      fill_in "Password", with: DEFAULT_USER_PASSWORD
      click_button "Log in"

      expect(page).to have_current_path(dashboard_path)
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
    let(:user_no_org) { User.create(email: 'no-org-user@example.org2', password: 'password!') }

    before do
      user_no_org.add_role(:org_user)
      visit new_user_session_path

      fill_in "Email", with: user_no_org.email
      fill_in "Password", with: user_no_org.password
      click_button "Log in"
    end

    it "redirects to 403" do
      expect(page).to have_current_path("/403")
    end
  end
end
