RSpec.feature "Organization management", type: :feature do
  before do
    sign_in(@user)
  end
  let!(:url_prefix) { "/#{@organization.to_param}" }
  scenario "When editing their organization, the user is prompted with placeholder text and a more helpful error message to ensure correct URL format" do
    visit url_prefix + "/organization/edit"
    fill_in "Url", with: "www.diaperbase.com"
    click_button "Update"

    fill_in "Url", with: "http://www.diaperbase.com"
    click_button "Update"
    expect(page.find(".alert")).to have_content "pdated"
  end
end
