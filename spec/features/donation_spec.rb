RSpec.feature "Donation management", type: :feature do
  before do
    sign_in(@user)
  end
  let!(:url_prefix) { "/#{@organization.to_param}" }

  scenario "User must confirm extremely large donation quantities", js: true do
    visit url_prefix + "/donations/new"
    fill_in "Quantity", with: 1_000_000

    accept_confirm do
      click_button "Save"
    end
  end
end
