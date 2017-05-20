RSpec.feature "Dashboard", type: :feature do
  before :each do
    @url_prefix = "/#{@organization.short_name}"
  end

  context "When visiting a new dashboard" do
    before(:each) do
      sign_in @user
      visit @url_prefix + "/dashboard"
    end

    scenario "User should see their organization name" do
      expect(page.find('.top-bar .organization-name')).to have_content(@organization.name)
    end
  end
end
