RSpec.describe "Organization management", type: :system, js: true do
  include ActionView::RecordIdentifier
  let!(:url_prefix) { "/#{@organization.to_param}" }

  context "while signed in as a normal user" do
    before do
      sign_in(@user)
    end

    it "can see summary details about the organization as a user" do
      visit url_prefix + "/organization"
    end

    it "cannot see 'Make user' button for admins" do
      visit url_prefix + "/organization"
      expect(page.find(".table.border")).to have_no_content "Make User"
    end
  end

  context "while signed in as an organization admin" do
    let!(:store) { create(:storage_location) }
    let!(:ndbn_member) { create(:ndbn_member, ndbn_member_id: "50000", account_name: "Best Place") }
    before do
      sign_in(@organization_admin)
    end

    describe "Viewing the organization" do
      it "can view organization details", :aggregate_failures do
        visit organization_path(@organization)

        expect(page.find("h1")).to have_text(@organization.name)
        expect(page).to have_link("Home", href: dashboard_path(@organization))

        expect(page).to have_content("Organization Info")
        expect(page).to have_content("Contact Info")
        expect(page).to have_content("Default email text")
        expect(page).to have_content("Users")
        expect(page).to have_content("Short Name")
        expect(page).to have_content("URL")
        expect(page).to have_content("Partner Profile Sections")
        expect(page).to have_content("Custom Partner Invitation Message")
        expect(page).to have_content("Child Based Requests?")
        expect(page).to have_content("Individual Requests?")
        expect(page).to have_content("Quantity Based Requests?")
        expect(page).to have_content("Show Year-to-date values on distribution printout?")
        expect(page).to have_content("Logo")
        expect(page).to have_content("Use One Step Invite and Approve partner process?")
      end
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

      it 'can select if the org repackages essentials' do
        choose('organization[repackage_essentials]', option: true)

        click_on "Save"
        expect(page).to have_content("Yes")
      end

      it 'can select if the org distributes essentials monthly' do
        choose('organization[distribute_monthly]', option: true)

        click_on "Save"
        expect(page).to have_content("Yes")
      end

      it 'can select if the org shows year-to-date values on the distribution printout' do
        choose('organization[ytd_on_distribution_printout]', option: false)

        click_on "Save"
        expect(page).to have_content("No")
      end

      it 'can set a default storage location on the organization' do
        select(store.name, from: 'Default Storage Location')

        click_on "Save"
        expect(page).to have_content(store.name)
      end

      it 'can set the NDBN Member ID' do
        select(ndbn_member.full_name)

        click_on "Save"
        expect(page).to have_content(ndbn_member.full_name)
      end

      it 'can select and deselect Required Partner Fields' do
        # select first option in from Required Partner Fields
        select('Media Information', from: 'organization_partner_form_fields', visible: false)
        click_on "Save"
        expect(page).to have_content('Media Information')
        expect(@organization.reload.partner_form_fields).to eq(['media_information'])
        # deselect previously chosen Required Partner Field
        click_on "Edit"
        unselect('Media Information', from: 'organization_partner_form_fields', visible: false)
        click_on "Save"
        expect(page).to_not have_content('Media Information')
        expect(@organization.reload.partner_form_fields).to eq([])
      end

      it "can disable if the org does NOT use single step invite and approve partner process" do
        choose("organization[one_step_partner_invite]", option: false)

        click_on "Save"
        expect(page).to have_content("No")
      end

      it "can enable if the org uses single step invite and approve partner process" do
        choose("organization[one_step_partner_invite]", option: true)

        click_on "Save"
        expect(page).to have_content("Yes")
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

    it "can see 'Make user' button for admins" do
      create(:organization_admin)
      visit url_prefix + "/organization"
      expect(page.find(".table.border")).to have_content "Make User"
    end

    it "can deactivate a user in the organization" do
      user = create(:user, name: "User to be deactivated")
      visit url_prefix + "/organization"
      accept_confirm do
        click_button dom_id(user, "dropdownMenu")
        click_link dom_id(user)
      end

      expect(page).to have_content("User has been deactivated")
      expect(user.reload.discarded_at).to be_present
    end

    it "can re-activate a user in the organization" do
      user = create(:user, :deactivated)
      visit url_prefix + "/organization"
      accept_confirm do
        click_button dom_id(user, "dropdownMenu")
        click_link dom_id(user)
      end

      expect(page).to have_content("User has been reactivated")
      expect(user.reload.discarded_at).to be_nil
    end
  end
end
