RSpec.describe "Authorization", type: :system, js: true do
  it "redirects to the dashboard when unauthorized user attempts access" do
    sign_in(@user)
    visit "/admin/dashboard"

    expect(page.current_path).to eq(dashboard_path(@user.organization))
    expect(page.find(".alert")).to have_content "Access Denied"
  end

  it "redirects to the organization dashboard when authorized" do
    sign_in(@user)
    visit dashboard_path(@user.organization)

    expect(current_path).to eql "/#{@user.organization.short_name}/dashboard"
  end
end
