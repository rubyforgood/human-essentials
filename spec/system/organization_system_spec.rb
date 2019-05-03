RSpec.feature "Organization management", type: :feature do
    let!(:url_prefix) { "/#{@organization.to_param}" }

    context "while signed in as a normal user" do
        before do
        sign_in(@user)
        end

        scenario "The user can see summary details about the organization" do
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
        scenario "the user is prompted with placeholder text and a more helpful error message to ensure correct URL format" do
            fill_in "Url", with: "www.diaperbase.com"
            click_on "Save"

            fill_in "Url", with: "http://www.diaperbase.com"
            click_on "Save"
            expect(page.find(".alert")).to have_content "pdated"
        end
        end

        scenario "Can add a new user to an organization" do
        allow(User).to receive(:invite!).and_return(true)
        visit url_prefix + "/organization"
        click_on "Invite User to this Organization"
        within "#addUserModal" do
            fill_in "email", with: "some_new_user@website.com"
            click_on "Invite User"
        end
        expect(page).to have_content("invited to organization")
        end

        scenario "Can re-invite a user to an organization after 7 days" do
        create(:user, name: "Ye Olde Invited User", invitation_sent_at: Time.current - 7.days)
        visit url_prefix + "/organization"
        expect(page).to have_xpath("//i[@alt='Re-send invitation']")
        end
    end
end
