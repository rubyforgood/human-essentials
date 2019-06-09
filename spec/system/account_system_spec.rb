RSpec.describe "User account management", type: :system, js: true do
  subject { "/users/edit" }

  before do
    sign_in(@user)
    visit subject
  end

  it "should change an user name" do
    name = @user.name + "aaa"
    fill_in "Name", with: name
    fill_in "user_current_password", with: @user.password
    click_button "Save"

    expect(page).to have_content(name)
  end

  it "should change the email" do
    email = "example@example.com"
    fill_in "Email", with: email
    fill_in "user_current_password", with: @user.password
    click_button "Save"

    expect(page).to have_content('Your account has been updated successfully.')
  end

  it "should fail when the email is invalid" do
    invalid_email = "invalid email"
    fill_in "Email", with: invalid_email
    fill_in "user_current_password", with: @user.password
    click_button "Save"

    expect(page).to have_content('is invalid')
  end
end
