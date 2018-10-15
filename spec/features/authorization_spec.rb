RSpec.feature "Authorization", type: :feature do
  scenario "should redirect to dashboard when unauthorized user attempts access" do
    sign_in(@user)
    visit "/admin/dashboard"
    expect(page.find("h1")).to have_content "Dashboard"
    expect(page.find(".alert")).to have_content "Access Denied"
  end

  scenario "redirect to organization dashboard when authorized" do
    sign_in(@user)
    visit "/#{@organization.name}/dashboard"
    expect(current_path).to eql "/DEFAULT/dashboard"
  end
end
