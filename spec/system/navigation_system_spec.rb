RSpec.describe "Navigation", type: :system, js: true do
  describe "sidebar on home" do
    before do
      sign_in(user)
      visit "/"
    end

    context "with organization admin" do
      let(:user) { create(:organization_admin) }
      # 2389 Links was missing Forecasting, which is available to an organization admin
      let(:links) { ["Dashboard", "Donations", "Purchases", "Requests", "Product Drives", "Distributions", "Pick Ups & Deliveries", "Partner Agencies", "Inventory", "Community", "Reports", "My Organization"] }

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

      describe "Inventory submenu" do
        let(:reports) { ["Inventory Audit"] }
        before { click_link("Inventory") }

        it "shows submenu navigation options" do
          sidebar = page.find(".sidebar")
          reports.each do |report_name|
            expect(sidebar).to have_link(report_name)
          end
        end
      end

      describe "Reports submenu" do
        let(:reports) { ["Annual Survey", "Distributions - By County"] }
        before { click_link("Reports") }

        it "shows submenu navigation options" do
          sidebar = page.find(".sidebar")
          reports.each do |report_name|
            expect(sidebar).to have_link(report_name)
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
      let(:links) { ["Admin Dashboard", "Barcode Items", "Base Items", "Organizations", "Partners", "Users", "Announcements", "Account Requests", "FAQ"] }

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
