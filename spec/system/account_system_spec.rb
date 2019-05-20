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
end