require "rails_helper"

RSpec.describe "Static error pages", type: :feature do
  let(:user) { create(:user) }

  %w[403 404 422 500].each do |code|
    context "on the #{code} error page" do
      it "offers a Home link instead of a log out link" do
        sign_in(user)
        visit "/#{code}"

        expect(page).to have_no_link("Log out")

        click_link "Home", match: :first
        expect(page).to have_current_path(dashboard_path)
      end

      it "sends signed-out visitors home to the landing page" do
        visit "/#{code}"

        click_link "Home", match: :first
        expect(page).to have_current_path(root_path)
      end
    end
  end
end
