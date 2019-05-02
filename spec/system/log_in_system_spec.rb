RSpec.describe "Authentication", type: :system do
  describe "Success" do
    it "should show dashboard upon signin" do
      sign_in(@user)
      visit "/"
      expect(page.find("h1")).to have_content "Dashboard"
    end
  end
end