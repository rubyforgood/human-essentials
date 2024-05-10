RSpec.describe "Navigation", type: :system, js: true, skip_seed: true do
  describe "sidebar on home" do
    before do
      sign_in(user)
      visit "/"
    end

    context "with organization user" do
      let(:user) { create(:organization_admin) }
      # 2389 Links was missing Forecasting, which is available to an organization admin
      let(:links) { ["Dashboard", "Donations", "Purchases", "Requests", "Product Drives", "Distributions", "Pick Ups & Deliveries", "Partner Agencies", "Inventory", "Community", "Reporting & Auditing", "Historical Trends", "My Organization"] }

      it "shows navigation options" do
        sidebar = page.find(".sidebar")
        links.each do |title|
          expect(sidebar).to have_link(title)
        end
      end

      context "with collapsed sidebar" do
        before { click_link("collapse") }

        it "hides text" do
          page.all(".nav-sidebar > .nav-item > .nav-link").each do |link| # rubocop:disable Rails/FindEach
            label = link.find("p", visible: :all)
            expect(label).to match_style(width: "0px")
            expect(links).to include(label.text(:all))
          end
        end
      end
    end
  end

  describe "sidebar on admin" do
    before do
      sign_in(user)
      visit "/admin"
    end

    context "with superadmin user" do
      let(:user) { create(:super_admin) }
      let(:links) { ["Admin Dashboard", "Barcode Items", "Base Items", "Organizations", "Partners", "Users", "Announcements", "Account Requests", "FAQ", "My Organization"] }

      it "shows navigation options" do
        sidebar = page.find(".sidebar")
        links.each do |title|
          expect(sidebar).to have_link(title)
        end
      end

      it "shows NDBN Member Upload under Organizations" do
        sidebar = page.find(".sidebar")
        click_link("Organizations")
        expect(sidebar).to have_link("NDBN Member Upload")
      end

      context "with collapsed sidebar" do
        before { click_link("collapse") }

        it "hides text" do
          page.all(".nav-sidebar > .nav-item > .nav-link").each do |link| # rubocop:disable Rails/FindEach
            label = link.find("p", visible: :all)
            expect(label).to match_style(width: "0px")
            expect(links).to include(label.text(:all))
          end
        end
      end
    end
  end
end
