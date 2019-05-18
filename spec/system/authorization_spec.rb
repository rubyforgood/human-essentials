RSpec.describe "Authorization", type: :system do
  it "redirects to the dashboard when unauthorized user attempts access" do
    sign_in(@user)
    visit "/admin/dashboard"

    expect(page.find("h1")).to have_content "Dashboard"
    expect(page.find(".alert")).to have_content "Access Denied"
  end

  it "redirects to the organization dashboard when authorized" do
    sign_in(@user)
    visit "/#{@organization.name}/dashboard"

    expect(current_path).to eql "/DEFAULT/dashboard"
  end
end
