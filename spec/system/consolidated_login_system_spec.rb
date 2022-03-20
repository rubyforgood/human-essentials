RSpec.describe "Consolidated login with email lookup", type: :system, js: true do
  before do
    visit "/"
    click_button "Login"
  end

  describe "flow for a user with both partner and bank logins" do
    let!(:user) do
      @user.organization.update!(name: "A Bank")
      @user
    end

    let!(:partner_user) do
      @partner.primary_partner_user.tap do |u|
        u.update!(email: user.email, password: "password!", password_confirmation: "password!")
        u.partner.update!(name: "A Partner")
      end
    end

    before do
      fill_in "Email", with: user.email
      click_button "Continue"
    end

    it "prefils email and presents a dropdown allowing the user to pick which org they'd like to log in for" do
      expect(page.find_field("Email").value).to eql(user.email)
      expect(page).to have_text("BANK ACCOUNT")
      expect(page).to have_text("PARTNER ACCOUNT")
    end

    it "allows successful login based on the organization selected" do
      choose "PARTNER ACCOUNT"
      click_button "Continue"

      fill_in "Password", with: user.password
      click_button "Log in"

      expect(page).to have_current_path "/partners/dashboard"
    end
  end

  describe "feedback on an unregistered email" do
    before do
      fill_in "Email", with: "non-existent@example.com"
      click_button "Continue"
    end

    it "lets the user know the email is not recognized" do
      email_group = page.find ".form-group.user_email"
      expect(email_group).to have_css "input.is-invalid"
      expect(email_group).to have_text "Email not found"
      expect(email_group.find_field("Email").value).to eq "non-existent@example.com"
    end
  end
end
