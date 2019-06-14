RSpec.describe "User account management", type: :system, js: true do
  subject { "/users/edit" }

  before do
    sign_in(@user)
    visit subject
  end

  it "should change a user name" do
    name = @user.name + "aaa"
    fill_in "Name", with: name
    fill_in "user_current_password", with: @user.password
    click_button "Save"

    expect(page).to have_content(name)
  end

  it "should change a user email" do
    email = "test@diaper.com"
    fill_in "Email", with: email
    fill_in "user_current_password", with: @user.password
    click_button "Save"
    visit "/users/edit"

    expect(page).to have_field("user[email]", :with => email)
  end
end