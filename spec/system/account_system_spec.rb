RSpec.describe "User account management", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  subject { "/users/edit" }

  before do
    sign_in(user)
  end

  context 'when in staging' do
    before do
      allow(Rails.env).to receive(:staging?).and_return(true)
      visit subject
    end

    it 'should display staging warning' do
      expect(page).to have_selector('.staging-warning')
    end

    it 'should not allow the user to change staging credentials' do
      expect(page).to have_button('Save', disabled: true)
    end
  end

  context 'when not in staging' do
    before do
      allow(Rails.env).to receive(:staging?).and_return(false)
      visit subject
    end

    it "should change an user name" do
      name = user.name + "aaa"
      fill_in "Name", with: name
      fill_in "user_current_password", with: DEFAULT_USER_PASSWORD
      click_button "Save"

      expect(page).to have_content(name)
    end

    it "should change the email" do
      email = "example@example.com"
      fill_in "Email", with: email
      fill_in "user_current_password", with: DEFAULT_USER_PASSWORD
      click_button "Save"

      expect(page).to have_content('Your account has been updated successfully.')
    end

    it "should fail when the email is invalid" do
      invalid_email = "invalid email"
      fill_in "Email", with: invalid_email
      fill_in "user_current_password", with: DEFAULT_USER_PASSWORD
      click_button "Save"

      expect(page).to have_content('is invalid')
    end
  end
end
