RSpec.describe "Consolidated login with email lookup", type: :system, js: true do
  describe "comprehensive flow for a user with both partner and bank logins" do
    let(:user) { @user }
    let(:partner_user) do
      @partner.primary_partner_user.tap do |u|
        u.update!(email: user.email, password: "password!", password_confirmation: "password!")
      end
    end

    before do
      user.organization.update!(name: "A Bank")
      partner_user.partner.update!(name: "A Partner")

      visit "/"
      click_button "Login"
      fill_in "Email", with: user.email
      click_button "Continue"
    end

    it "prefils email and presents a dropdown allowing the user to pick which org they'd like to log in for" do
      expect(page.find_field("Email").value).to eql(user.email)
      expect(page).to have_select("user[organization]", options: ["A Bank", "A Partner"])
    end

    it "allows successful login based on the organization selected" do
      select "A Partner", from: "user[organization]"
      click_button "Continue"

      fill_in "Password", with: user.password
      click_button "Log in"

      expect(page).to have_current_path "/partners/dashboard"
    end
  end
end
