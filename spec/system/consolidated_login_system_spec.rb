RSpec.describe "Consolidated login with email lookup", type: :system, js: true do
  let(:user) { @user }
  let(:partner_user) do
    @partner.primary_partner_user.tap do |u|
      u.update!(password: "password!", password_confirmation: "password!")
    end
  end

  before do
    visit "/"
    click_button "Login"
  end

  context "bank user" do
    before do
      fill_in "Email", with: user.email
      click_button "Continue"
    end

    it "directs user to the bank login with email prefilled" do
      expect(page).to have_title("Human Essentials | Bank | Log in")
      expect(page.find_field("Email").value).to eql(user.email)
    end

    it "logs in to the bank dashboard" do
      fill_in "Password", with: user.password
      click_button "Log in"

      expect(page).to have_current_path dashboard_path(user.organization)
    end
  end

  context "partner user" do
    before do
      fill_in "Email", with: partner_user.email
      click_button "Continue"
    end

    it "directs user to the partner login with email prefilled" do
      expect(page).to have_title("Human Essentials | Partner | Log in")
      expect(page.find_field("Email").value).to eql(partner_user.email)
    end

    it "logs in to the partner dashboard" do
      fill_in "Password", with: partner_user.password
      click_button "Log in"

      expect(page).to have_current_path "/partners/dashboard"
    end
  end
end
