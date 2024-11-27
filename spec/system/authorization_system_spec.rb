RSpec.describe "Authorization", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  it "redirects to the dashboard when unauthorized user attempts access" do
    sign_in(user)
    visit "/admin/dashboard"

    expect(page.find("h1")).to have_content "Dashboard"
    expect(page.find(".alert")).to have_content "Access Denied"
  end

  it "redirects to the organization dashboard when authorized" do
    sign_in(user)
    visit dashboard_path

    expect(current_path).to eql "/dashboard"
  end
end
