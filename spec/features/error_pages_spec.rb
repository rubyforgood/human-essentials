require "rails_helper"

RSpec.describe "Error Pages", type: :feature do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  context "on 403 error page" do
    it "allows user to log out" do
      visit "/403"
      expect(page).to have_link("Log out")

      click_link "Log out"
      expect(page).to have_content("Signed out successfully")
    end
  end

  context "on 404 error page" do
    it "allows user to log out" do
      visit "/404"
      expect(page).to have_link("Log out")

      click_link "Log out"
      expect(page).to have_content("Signed out successfully")
    end
  end

  context "on 422 error page" do
    it "allows user to log out" do
      visit "/422"
      expect(page).to have_link("Log out")

      click_link "Log out"
      expect(page).to have_content("Signed out successfully")
    end
  end

  context "on 500 error page" do
    it "allows user to log out" do
      visit "/500"
      expect(page).to have_link("Log out")

      click_link "Log out"
      expect(page).to have_content("Signed out successfully")
    end
  end
end
