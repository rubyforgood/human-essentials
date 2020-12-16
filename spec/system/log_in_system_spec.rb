RSpec.describe "Authentication", type: :system, js: true do
  describe "Success" do
    it "should show dashboard upon signin" do
      sign_in(@user)
      visit "/"
      expect(page.find("h1")).to have_content "Dashboard"
    end
  end

  describe "Deactivated user" do
    before do
      create(:user, :deactivated, email: "deactivated@exmaple.com")
    end

    it "should not allow the user to log in" do
      visit "/users/sign_in"
      fill_in "user_email", with: "deactivated@example.com"
      fill_in "user_password", with: "password"
      find('input[name="commit"]').click

      expect(page).to have_content("Invalid Email or password")
    end
  end
end
