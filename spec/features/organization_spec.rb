RSpec.feature "Organization management", type: :feature do
  before do
    sign_in(@user)
  end
  let!(:url_prefix) { "/#{@organization.to_param}"}
  scenario "When editing their organization, the user can enter a URL with or without http://" do
  	visit url_prefix + '/organization/edit'
    fill_in "Url", with: "www.diaperbase.com"
    click_button "Update"

    expect(page.find('.url .error')).to have_content "www.example.com"

    fill_in "Url", with: "http://www.diaperbase.com"
    click_button "Update"
    expect(page.find('.flash.success')).to have_content "pdated"
  end
end