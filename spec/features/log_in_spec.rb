RSpec.feature "Authentication", type: :feature do

  scenario "User is not logged in" do
    visit "/#{@organization.to_param}/dashboard"
    expect(page.find('.flash.alert')).to have_content "need to sign in"
  end

end
