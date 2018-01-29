RSpec.feature "Authorization", type: :feature do

  scenario "should redirect to dashboard when unauthorized user attempts access" do
    sign_in(@user)
    visit "/admins"
    expect(page.find('li a.active[disabled]')).to have_content "Dashboard"
    expect(page.find('.flash.alert')).to have_content "Access Denied"
  end
  
end
