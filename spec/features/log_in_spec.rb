RSpec.feature "Authentication", type: :feature do

  scenario "should display login page when user is not logged in" do
    visit "/#{@organization.to_param}/dashboard"
    expect(page.find('.flash.alert')).to have_content "need to sign in"
  end

  describe "Success" do

    scenario "should show dashboard upon signin" do
      sign_in(@user)
      visit "/"
      expect(page.find('li a.active[disabled]')).to have_content "Dashboard"
    end

  end

end
