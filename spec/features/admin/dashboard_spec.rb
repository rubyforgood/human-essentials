RSpec.feature "Dashboard" do
  context "When the super admin user also has an organization assigned" do
    before do
      @super_admin.organization = @organization
      @super_admin.save
      sign_in(@super_admin)
    end

    scenario "the side and top nav both have a link to return to their organization dashboard" do
      visit admin_dashboard_path
      within "section.sidebar" do
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
    end

    scenario "the side and top navs DO NOT have a link to the organization dashboard" do
      visit admin_dashboard_path
      within "section.sidebar" do
        expect(page).not_to have_xpath("//li/a[@href='#{dashboard_path(@organization.short_name)}']")
      end
      within "nav.navbar" do
        expect(page).not_to have_xpath("//li/a[@href='#{dashboard_path(@organization.short_name)}']")
      end
    end
  end
end