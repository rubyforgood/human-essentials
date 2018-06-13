RSpec.feature "User account management", type: :feature do
  before do
    sign_in(@user)
    visit "/users/edit"
  end

  scenario "User can change their name" do
    name = @user.name + "aaa"
    fill_in "Name", with: name
    fill_in "user_current_password", with: @user.password
    click_button "Update"

    expect(page).to have_content(name)
  end
end
