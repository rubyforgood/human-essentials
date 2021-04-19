RSpec.describe "Authorization", type: :system, js: true do
  before do
    allow(DiaperPartnerClient).to receive(:get).and_return([])
  end

  it "redirects to the dashboard when unauthorized user attempts access" do
    sign_in(@user)
    visit "/admin/dashboard"

    expect(page.find("h1")).to have_content "Dashboard"
    expect(page.find(".alert")).to have_content "Access Denied"
  end

  it "redirects to the organization dashboard when authorized" do
    sign_in(@user)
    visit dashboard_path(@user.organization)

    expect(current_path).to eql "/#{@user.organization.short_name}/dashboard"
  end
end
