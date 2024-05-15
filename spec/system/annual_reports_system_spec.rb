RSpec.describe "Annual Reports", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  let(:url_prefix) { "/#{organization.short_name}" }

  context "while signed in as an organization admin" do
    subject { reports_annual_reports_path }
    let!(:purchase) { create(:purchase, :with_items, item_quantity: 10, issued_at: 1.year.ago, organization: organization) }

    before do
      sign_in organization_admin
      visit subject
    end

    it("exists") do
      expect(page).to have_content("Reports are available")
    end

    it("has the report from last year, if there is a purchase from last year") do
      year = 1.year.ago.year
      expect(page).to have_content(year)
    end

    it "has all the sub-reports we expect" do
      visit subject
      year = 1.year.ago.year
      click_on(year.to_s)
      expect(page).to have_content("Diaper Acquisition")
      expect(page).to have_content("Warehouse and Storage")
      expect(page).to have_content("Adult Incontinence")
      expect(page).to have_content("Other Items")
      expect(page).to have_content("Partner Agencies and Service Area")
      expect(page).to have_content("Children Served")
      expect(page).to have_content("Year End Summary")
      expect(page).to have_content("Period Supplies")
    end
  end
end
