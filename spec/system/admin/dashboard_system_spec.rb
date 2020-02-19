RSpec.describe "Dashboard", type: :system, js: true do
  subject { admin_dashboard_path }

  context "When the super admin user also has an organization assigned" do
    before do
      @super_admin.organization = @organization
      @super_admin.save
      sign_in(@super_admin)
      visit subject
    end

    it "displays a link to return to their organization" do
      expect(page).to have_link("My Organization")
    end
  end

  context "When the super admin user does not have an organization assigned" do
    before do
      @super_admin.organization = nil
      @super_admin.save
      sign_in(@super_admin)
      visit subject
    end

    it "DOES NOT have a link to the organization" do
      expect(page).not_to have_link("My Organization")
    end
  end
end