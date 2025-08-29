RSpec.describe "Organization management", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }
  let(:super_admin_org_admin) { create(:super_admin_org_admin, organization: organization) }
  let!(:storage_location) { create(:storage_location, :with_items, organization: organization) }
  let!(:ndbn_member) { create(:ndbn_member) }

  include ActionView::RecordIdentifier

  shared_examples "organization role management checks" do |user_factory|
    let!(:managed_user) { create(user_factory, name: "User to be managed", organization: organization) }

    it 'can remove that user from the organization' do
      visit organization_path
      accept_confirm do
        click_button dom_id(managed_user, "dropdownMenu")
        click_link "Remove User"
      end

      expect(page).to have_content("User has been removed!")
      expect(managed_user.has_role?(Role::ORG_USER)).to be false
    end

    it "can promote that user from the organization" do
      visit organization_path
      accept_confirm do
        click_button dom_id(managed_user, "dropdownMenu")
        click_link "Promote to Admin"
      end

      expect(page).to have_content("User has been promoted!")
      expect(managed_user.has_role?(Role::ORG_ADMIN, organization)).to be true
    end

    it "can demote that user from the organization" do
      managed_user.add_role(Role::ORG_ADMIN, organization)
      visit organization_path
      accept_confirm do
        click_link "Demote to User"
      end

      expect(page).to have_content("User has been demoted!")
      expect(managed_user.has_role?(Role::ORG_ADMIN, organization)).to be false
    end
  end

  context "while signed in as an organization admin" do
    before do
      sign_in(organization_admin)
    end

    describe "Editing the organization" do
      let(:partner) { create(:partner, organization: organization) }

      before do
        visit edit_organization_path
      end

      it "is prompted with placeholder text and a more helpful error message to ensure correct URL format as a user" do
        fill_in "URL", with: "notavalidemail"
        click_on "Save"
        expect(page.find(".alert")).to have_content "Url it should look like 'http://www.example.com'"

        fill_in "URL", with: "http://www.diaperbase.com"
        click_on "Save"
        expect(page.find(".alert")).to have_content "Updated"
      end

      def post_form_submit
        expect(page.find(".alert")).to have_content "Updated your organization!"
      end

      it_behaves_like "deadline and reminder form", "organization", "Save", :post_form_submit

      it "the deadline day form's reminder and deadline dates are consistent with the dates calculated by the FetchPartnersToRemindNowService and DeadlineService" do
        choose "Day of Month"
        fill_in "organization_reminder_schedule_service_day_of_month", with: safe_add_days(Time.zone.now, 1).day
        fill_in "Deadline day in reminder email", with: safe_add_days(Time.zone.now, 2).day

        reminder_text = find('small[data-deadline-day-target="reminderText"]').text
        reminder_text.slice!("Your next reminder date is ")
        reminder_text.slice!(".")
        shown_recurrence_date = Time.zone.strptime(reminder_text, "%a %b %d %Y")

        deadline_text = find('small[data-deadline-day-target="deadlineText"]').text
        deadline_text.slice!("The deadline on your next reminder email will be ")
        deadline_text.slice!(".")
        shown_deadline_date = Time.zone.strptime(deadline_text, "%a %b %d %Y")

        click_on "Save"
        organization.reload

        expect(Partners::FetchPartnersToRemindNowService.new.fetch).to_not include(partner)

        travel_to shown_recurrence_date

        expect(Partners::FetchPartnersToRemindNowService.new.fetch).to include(partner)
        expect(DeadlineService.new(deadline_day: DeadlineService.get_deadline_for_partner(partner)).next_deadline.in_time_zone(Time.zone)).to be_within(1.second).of shown_deadline_date

        expect(page).to have_content("Your next reminder date is #{reminder_text}.")
        expect(page).to have_content("The deadline on your next reminder email will be #{deadline_text}.")
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
        select(storage_location.name, from: 'Default Storage Location')

        click_on "Save"
        expect(page).to have_content(storage_location.name)
      end

      it 'can set the NDBN Member ID' do
        expect(page).to have_content('NDBN membership ID')
        select(ndbn_member.full_name)

        click_on "Save"
        expect(page).to have_content(ndbn_member.full_name)
      end

      it 'can select and deselect Required Partner Fields' do
        # select first option in from Required Partner Fields
        select('Media Information', from: 'organization_partner_form_fields', visible: false)
        click_on "Save"
        expect(page).to have_content('Media Information')
        expect(organization.reload.partner_form_fields).to eq(['media_information'])
        # deselect previously chosen Required Partner Field
        click_on "Edit"
        unselect('Media Information', from: 'organization_partner_form_fields', visible: false)
        click_on "Save"
        expect(page).to_not have_content('Media Information')
        expect(organization.reload.partner_form_fields).to eq([])
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
      visit organization_path
      click_on "Invite User to this Organization"
      within "#addUserModal" do
        fill_in "email", with: "some_new_user@website.com"
        click_on "Invite User"
      end
      expect(page).to have_content("invited to organization")
    end

    context "managing a user from the organization" do
      include_examples "organization role management checks", :user
    end

    context "managing a super admin user from the organization" do
      include_examples "organization role management checks", :super_admin
    end
  end

  context "while signed in as a super admin" do
    before do
      sign_in(super_admin_org_admin)
    end

    before(:each) do
      visit admin_dashboard_path
      within ".main-header" do
        click_on super_admin_org_admin.name.to_s
      end
      click_link "Switch to: #{organization.name}"
    end

    context "managing a user from the organization" do
      include_examples "organization role management checks", :user
    end

    context "managing a super admin user from the organization" do
      include_examples "organization role management checks", :super_admin
    end
  end
end
