require "rails_helper"

# The hub replaced a sidebar group of fifteen. Its job is that every report stays reachable and
# the rail still says where you are, so that is what these cover -- not how it looks.
RSpec.describe "Reports hub", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before do
    sign_in(user)
    visit reports_path
  end

  it "groups the reports by subject" do
    expect(page).to have_css("h1", text: "Reports")
    ["Distributions", "Donations", "Purchases", "Product drives", "Requests", "Everything else"].each do |section|
      expect(page).to have_css("h2", text: section)
    end
  end

  it "links to every report, and every link resolves" do
    hrefs = page.all("main ul a").map { |a| a[:href] }
    expect(hrefs.size).to eq(15)

    hrefs.each do |href|
      visit href
      expect(page.status_code).to eq(200), "#{href} returned #{page.status_code}"
    end
  end

  it "describes each report rather than only naming it" do
    expect(page).to have_content("How much of each item went out, broken down by partner.")
    expect(page).to have_content("Cached, so up to a day behind.")
  end

  describe "the sidebar" do
    it "carries one Reports entry rather than a group of fifteen" do
      expect(page).to have_css("aside nav a", text: "Reports")
      expect(page).to have_no_css("aside nav button", text: "Reporting")
    end

    it "keeps Reports marked as current while inside a report" do
      visit reports_distributions_summary_path
      expect(page).to have_css('aside nav a[aria-current="page"]', text: "Reports")

      visit historical_trends_donations_path
      expect(page).to have_css('aside nav a[aria-current="page"]', text: "Reports")
    end
  end
end
