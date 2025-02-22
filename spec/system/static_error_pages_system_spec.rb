require "rails_helper"

# Historically the static error pages loaded the application's JavaScript
# which could cause errors in the console. This test makes sure that
# the static pages load without any JavaScript errors.
RSpec.describe "Static Error Pages", type: :system do
  it "renders the 403 page with the correct headline" do
    visit "/403"
    expect(page).to have_css("h2.headline", text: "403")
  end

  it "renders the 404 page with the correct headline" do
    visit "/404"
    expect(page).to have_css("h2.headline", text: "404")
  end

  it "renders the 422 page with the correct headline" do
    visit "/422"
    expect(page).to have_css("h2.headline", text: "422")
  end

  it "renders the 500 page with the correct headline" do
    visit "/500"
    expect(page).to have_css("h2.headline", text: "500")
  end
end
