RSpec.describe "Dashboard", type: :system, js: true do
  subject { admin_dashboard_path }

  context "When the super admin user also has an organization assigned" do
    before do
      @super_admin.organization = @organization
      @super_admin.save
      sign_in(@super_admin)
      visit subject
    end

    xit "displays a link to return to their organization dashboard on both the side and top nav" do
      within ".navbar-static-side" do
        expect(page).to have_xpath("//li/a[@href='#{dashboard_path(@organization.short_name)}']")
      end
      within "nav.navbar" do
        expect(page).to have_xpath("//li/a[@href='#{dashboard_path(@organization.short_name)}']")
      end
    end
  end

  context "When the super admin user does not have an organization assigned" do
    before do
      @super_admin.organization = nil
      @super_admin.save
      sign_in(@super_admin)
      visit subject
    end

    skip scenario "the side and top navs DO NOT have a link to the organization dashboard" do
      visit admin_dashboard_path
      within ".navbar-static-side" do
        expect(page).not_to have_xpath("//li/a[@href='#{dashboard_path(@organization.short_name)}']")
      end
      within ".navbar-static-top" do
        expect(page).not_to have_xpath("//li/a[@href='#{dashboard_path(@organization.short_name)}']")
      end
    end
  end
end