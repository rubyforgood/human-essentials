RSpec.describe "Organization management", type: :system, js: true do
  let!(:url_prefix) { "/#{@organization.to_param}" }

  context "while signed in as a normal user" do
    before do
      sign_in(@user)
    end

    it "can see summary details about the organization as a user" do
      visit url_prefix + "/organization"
    end
  end
  context "while signed in as an organization admin" do
    before do
      sign_in(@organization_admin)
    end

    describe "Editing the organization" do
      before do
        visit url_prefix + "/manage/edit"
      end
      it "is prompted with placeholder text and a more helpful error message to ensure correct URL format as a user" do
        fill_in "Url", with: "www.diaperbase.com"
        click_on "Save"

        fill_in "Url", with: "http://www.diaperbase.com"
        click_on "Save"
        expect(page.find(".alert")).to have_content "pdated"
      end
      it "can set a reminder and a deadline day" do
        fill_in "organization_reminder_day", with: 12
        fill_in "organization_deadline_day", with: 16

        click_on "Save"
        expect(page.find(".alert")).to have_content "Updated"
      end

      it "cannot set a reminder day after deadline day" do
        fill_in "organization_reminder_day", with: 12
        fill_in "organization_deadline_day", with: 1

        click_on "Save"
        expect(page.find(".alert.alert-danger.alert-dismissible")).to have_content "Failed to update"
      end
    end

    it "can add a new user to an organization" do
      allow(User).to receive(:invite!).and_return(true)
      visit url_prefix + "/organization"
      click_on "Invite User to this Organization"
      within "#addUserModal" do
        fill_in "email", with: "some_new_user@website.com"
        click_on "Invite User"
      end
      expect(page).to have_content("invited to organization")
    end

    it "can re-invite a user to an organization after 7 days" do
      create(:user, name: "Ye Olde Invited User", invitation_sent_at: Time.current - 7.days)
      visit url_prefix + "/organization"
      expect(page).to have_xpath("//i[@alt='Re-send invitation']")
    end
  end
end
