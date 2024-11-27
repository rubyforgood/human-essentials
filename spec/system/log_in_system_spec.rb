RSpec.describe "Authentication", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  describe "Success" do
    it "should show dashboard upon signin" do
      sign_in(user)
      visit "/"
      expect(page.find("h1")).to have_content "Dashboard"
    end
  end

  describe "User with no roles" do
    before do
      create(:user, :no_roles, email: "no_role_user@example.com")
    end

    it "should not allow the user to log in" do
      visit "/users/sign_in"
      fill_in "user_email", with: "no_role_user@example.com"
      fill_in "user_password", with: DEFAULT_USER_PASSWORD
      find('input[name="commit"]').click
      expect(page).to have_content("You need to sign in before continuing.")
    end
  end

  describe "Deactivated user" do
    before do
      create(:user, :deactivated, email: "deactivated@example.com")
    end

    it "should not allow the user to log in" do
      visit "/users/sign_in"
      fill_in "user_email", with: "deactivated@example.com"
      fill_in "user_password", with: DEFAULT_USER_PASSWORD
      find('input[name="commit"]').click
      expect(page).to have_content("Invalid Email or password")
    end
  end

  describe 'Showing the modal warning in staging' do
    ["/users/sign_in", "/users/password/new"].each do |path|
      context "when accessing #{path} in the staging environment" do
        before do
          allow(Rails.env).to receive(:staging?).and_return(true)
          visit path
        end

        it 'should render the modal' do
          expect(page).to have_content 'This site is for TEST purposes only!'
        end
      end

      context "when accessing #{path} not in the staging environment" do
        before do
          allow(Rails.env).to receive(:staging?).and_return(false)
          visit path
        end

        it 'should not render the modal' do
          page.assert_no_selector('#warningModal')
        end
      end
    end
  end
end
