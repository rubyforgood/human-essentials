RSpec.describe "Organizations", type: :request do
  let(:organization) { create(:organization) }
  let!(:user) { create(:user, organization: organization) }
  let!(:organization_admin) { create(:organization_admin, organization: organization) }
  let!(:admin_user) { create(:organization_admin, organization: organization, name: "ADMIN USER") }
  let!(:unit) { create(:unit, name: "WolfPack", organization: organization) }
  let!(:store) { create(:storage_location, organization: organization) }
  let!(:ndbn_member) { create(:ndbn_member, ndbn_member_id: "50000", account_name: "Best Place") }
  let!(:super_admin_org_admin) { create(:super_admin_org_admin, organization: organization) }

  shared_examples "promote to admin check" do |user_factory, current_user|
    let!(:user_to_promote) { create(user_factory, name: "User to promote") }
    let(:response_path) {
      case current_user
      when :super_admin
        admin_organization_path(organization.id)
      when :non_super_admin
        organization_path
      end
    }

    it "runs correctly", :aggregate_failures do
      # Explicitly specify the organization_id, as current_organization will not
      # be set for super admins
      post promote_to_org_admin_organization_path(
        user_id: user_to_promote.id,
        organization_id: organization.id
      )
      expect(user_to_promote.reload.has_role?(Role::ORG_ADMIN, organization)).to be_truthy
      # The user_update_redirect_path will vary based on whether the logged in
      # user is a super admin or not
      expect(response).to redirect_to(response_path)
      expect(flash[:notice]).to eq("User has been promoted!")
    end
  end

  shared_examples "demote to user check" do |user_factory, current_user|
    let!(:user_to_demote) { create(user_factory, name: "User to demote", organization: organization) }
    let(:response_path) {
      case current_user
      when :super_admin
        admin_organization_path(organization.id)
      when :non_super_admin
        organization_path
      end
    }

    it "runs correctly", :aggregate_failures do
      # Explicitly specify the organization_id, as current_organization will not
      # be set for super admins
      post demote_to_user_organization_path(
        user_id: user_to_demote.id,
        organization_id: organization.id
      )
      expect(user_to_demote.reload.has_role?(Role::ORG_ADMIN, organization)).to be_falsey
      # The user_update_redirect_path will vary based on whether the logged in
      # user is a super admin or not
      expect(response).to redirect_to(response_path)
      expect(flash[:notice]).to eq("User has been demoted!")
    end
  end

  shared_examples "remove user check" do |user_factory, current_user|
    let!(:user_to_remove) { create(user_factory, name: "User to remove", organization: organization) }
    let(:response_path) {
      case current_user
      when :super_admin
        admin_organization_path(organization.id)
      when :non_super_admin
        organization_path
      end
    }

    it "runs correctly", :aggregate_failures do
      # Explicitly specify the organization_id, as current_organization will not
      # be set for super admins
      post remove_user_organization_path(
        user_id: user_to_remove.id,
        organization_id: organization.id
      )
      expect(user_to_remove.reload.has_role?(Role::ORG_USER, organization)).to be_falsey
      # The user_update_redirect_path will vary based on whether the logged in
      # user is a super admin or not
      expect(response).to redirect_to(response_path)
      expect(flash[:notice]).to eq("User has been removed!")
    end
  end

  context "While signed in as a normal user" do
    before do
      sign_in(user)
    end

    describe "GET #show" do
      before { get organization_path }

      it { expect(response).to be_successful }

      it 'load the current organization' do
        expect(assigns(:organization)).to have_attributes(
          name: organization.name,
          email: organization.email,
          url: organization.url
        )
      end

      it "can view organization details", :aggregate_failures do
        html = Nokogiri::HTML(response.body)
        expect(html.text).to include(organization.name)
        expect(html.css("a").text).to include("Home")
        expect(html.css("a").to_s).to include(dashboard_path)
        expect(html.text).to include("Organization Info")
        expect(html.text).to include("Address")
        expect(html.text).to include("Distribution email content")
        expect(html.text).to include("Users")
        expect(html.text).to include("URL")
        expect(html.text).to include("Partner Profile sections")
        expect(html.text).to include("Custom Partner invitation message")
        expect(html.text).to include("Enable Partners to make child-based Requests?")
        expect(html.text).to include("Enable Partners to make Requests by indicating number of individuals needing each Item?")
        expect(html.text).to include("Enable Partners to make quantity-based Requests?")
        expect(html.text).to include("Show year-to-date values on Distribution printout?")
        expect(html.text).to include("Logo")
        expect(html.text).to include("Use one-step Partner invite and approve process?")
        expect(html.text).to include("Receive email when Partner makes a Request?")
        expect(html.text).not_to include("Your next reminder date is ")
        expect(html.text).not_to include("The deadline on your next reminder email will be ")
      end

      it "displays the correct organization details" do
        intake_storage_location = create(:storage_location, organization:, name: "Intake Center")
        default_storage_location = create(:storage_location, organization:, name: "Default Center")

        organization.update!(intake_location: intake_storage_location.id, default_storage_location: default_storage_location.id)

        get organization_path

        expect(response.body).to include("Intake Center")
        expect(response.body).to include("Default Center")
      end

      context "when enable_packs flipper is on" do
        it "displays organization's custom units" do
          Flipper.enable(:enable_packs)
          get organization_path
          expect(response.body).to include "Wolf Pack"
        end
      end

      context "when enable_packs flipper is off" do
        it "does not display organization's custom units" do
          Flipper.disable(:enable_packs)
          get organization_path
          expect(response.body).to_not include "Wolf Pack"
        end
      end

      context "with a reminder schedule" do
        before do
          travel_to Time.zone.local(2020, 10, 10)
          valid_reminder_schedule = ReminderScheduleService.new({
            by_month_or_week: "day_of_month",
            every_nth_month: 1,
            day_of_month: 20
          }).to_ical
          organization.update(reminder_schedule_definition: valid_reminder_schedule)
        end

        it "reports the next date a reminder email will be sent" do
          get organization_path
          expect(response.body).to include "Your next reminder date is Tue Oct 20 2020."
          expect(response.body).not_to include "The deadline on your next reminder email will be Sun Oct 25 2020."
        end

        it "reports the deadline date that will be included in the next reminder email" do
          organization.update(deadline_day: 25)
          get organization_path
          expect(response.body).to include "Your next reminder date is Tue Oct 20 2020."
          expect(response.body).to include "The deadline on your next reminder email will be Sun Oct 25 2020."
        end
      end

      it "cannot see 'Demote to User' button for admins" do
        expect(response.body).to_not include "Demote to User"
      end
    end

    describe "GET #edit" do
      before { get edit_organization_path }

      it { expect(response).to redirect_to(dashboard_path) }
      it { expect(response).to have_error }
    end

    describe "PATCH #update" do
      let(:update_param) { { organization: { name: "Thunder Pants" } } }
      before { patch "/manage", params: update_param }

      it { expect(response).to redirect_to(dashboard_path) }
      it { expect(response).to have_error }
    end
  end

  context "While signed in as an organization admin" do
    before do
      sign_in(organization_admin)
    end

    describe "GET #show" do
      before { get organization_path }

      it "can view organization details", :aggregate_failures do
        html = Nokogiri::HTML(response.body)
        expect(html.text).to include(organization.name)
        expect(html.css("a").text).to include("Home")
        expect(html.css("a").to_s).to include(dashboard_path)
        expect(html.text).to include("Organization Info")
        expect(html.text).to include("Address")
        expect(html.text).to include("Distribution email content")
        expect(html.text).to include("Users")
        expect(html.text).to include("URL")
        expect(html.text).to include("Partner Profile sections")
        expect(html.text).to include("Custom Partner invitation message")
        expect(html.text).to include("Enable Partners to make child-based Requests?")
        expect(html.text).to include("Enable Partners to make Requests by indicating number of individuals needing each Item?")
        expect(html.text).to include("Enable Partners to make quantity-based Requests?")
        expect(html.text).to include("Show year-to-date values on Distribution printout?")
        expect(html.text).to include("Logo")
        expect(html.text).to include("Use one-step Partner invite and approve process?")
        expect(html.text).to include("Receive email when Partner makes a Request?")
      end

      context "when enable_packs flipper is on" do
        it "displays organization's custom units" do
          Flipper.enable(:enable_packs)
          get organization_path
          expect(response.body).to include "Wolf Pack"
        end
      end

      context "when enable_packs flipper is off" do
        it "does not display organization's custom units" do
          Flipper.disable(:enable_packs)
          get organization_path
          expect(response.body).to_not include "Wolf Pack"
        end
      end

      it "can see 'Demote to User' button for admins" do
        create(:organization_admin, organization: organization, name: "ADMIN USER")
        get organization_path
        expect(response.body).to include "Demote to User"
      end

      it "can see 'Promote to User' button for users" do
        get organization_path

        within(".content") do
          expect(response.body).to have_link("Actions")
        end

        within "#dropdown-toggle" do
          expect(response.body).to have_link("Promote User")
          expect(response.body).to have_link("Remove User")
        end
      end

      it "can re-invite a user to an organization after 7 days" do
        create(:user, name: "Ye Olde Invited User", invitation_sent_at: 7.days.ago)
        get organization_path
        expect(response.body).to include("Re-send invitation")
      end
    end

    describe "GET #edit" do
      before { get edit_organization_path }

      it { is_expected.to render_template(:edit) }
      it { expect(response).to be_successful }
      it 'initializing the given organization' do
        expect(assigns(:organization)).to be_a(Organization) &
                                          have_attributes(
                                            name: organization.name,
                                            email: organization.email,
                                            url: organization.url
                                          )
      end

      context "when enable_packs flipper is on" do
        it "should display custom units and units form" do
          Flipper.enable(:enable_packs)
          get edit_organization_path
          expect(response.body).to include("Custom request units used")
          expect(response.body).to include "WolfPack"
        end
      end

      context "when enable_packs flipper is off" do
        it "should not display custom units and units form" do
          Flipper.disable(:enable_packs)
          get edit_organization_path
          expect(response.body).to_not include("Custom request units used")
          expect(response.body).to_not include "WolfPack"
        end
      end
    end

    describe "PATCH #update" do
      let(:update_param) { { organization: { name: "Thunder Pants" } } }
      subject { patch "/manage", params: update_param }

      it "should be redirect after update" do
        subject
        expect(response).to redirect_to(organization_path)
      end

      it "can update name" do
        expect { subject }.to change { organization.reload.name }.to "Thunder Pants"
      end

      context "when organization can not be updated" do
        let(:update_param) { { organization: { name: nil } } }

        it "renders edit template with an error message" do
          expect(subject).to render_template(:edit)
          expect(flash[:error]).to be_present
        end
      end

      context "when the organization URL is updated" do
        let(:update_param) { { organization: { url: "http://www.diaperbase.com" } } }
        it "updates the organization's URL" do
          subject
          expect(response).to redirect_to(organization_path)
          follow_redirect!
          expect(response.body).to include("pdated")
        end
      end

      context "updates reminder and deadline days" do
        let(:update_param) { { organization: { reminder_day: 12, deadline_day: 16 } } }
        it "works" do
          subject
          expect(response).to redirect_to(organization_path)
          follow_redirect!
          expect(response.body).to include("Updated")
        end
      end

      context "updates repackage essentials setting" do
        let(:update_param) { { organization: { repackage_essentials: true } } }
        it "works" do
          subject
          expect(response).to redirect_to(organization_path)
          follow_redirect!
          expect(response.body).to include("Yes")
        end
      end

      context "can select if the org distributes essentials monthly" do
        let(:update_param) { { organization: { distribute_monthly: true } } }
        it "works" do
          subject
          expect(response).to redirect_to(organization_path)
          follow_redirect!
          expect(response.body).to include("Yes")
        end
      end

      context 'can select if the org shows year-to-date values on the distribution printout' do
        let(:update_param) { { organization: { ytd_on_distribution_printout: false } } }
        it "works" do
          subject
          expect(response).to redirect_to(organization_path)
          follow_redirect!
          expect(response.body).to include("No")
        end
      end

      context 'can set a default storage location on the organization' do
        let(:update_param) { { organization: { default_storage_location: store.id } } }
        it "works" do
          subject
          expect(response).to redirect_to(organization_path)
          follow_redirect!
          expect(response.body).to include(store.name)
        end
      end

      context 'can set the NDBN Member ID' do
        let(:update_param) { { organization: { ndbn_member_id: ndbn_member.id } } }
        it "works" do
          subject
          expect(response).to redirect_to(organization_path)
          follow_redirect!
          expect(response.body).to include(ndbn_member.full_name)
        end
      end

      context 'can select and deselect Required Partner Fields' do
        let(:update_param) { { organization: { partner_form_fields: ['media_information'] } } }
        it "works" do
          subject
          expect(response).to redirect_to(organization_path)
          follow_redirect!
          expect(response.body).to include('Media Information')
          expect(organization.reload.partner_form_fields).to eq(['media_information'])

          patch "/manage", params: { organization: { partner_form_fields: [] } }
          expect(response).to redirect_to(organization_path)
          follow_redirect!
          expect(response.body).to_not include('Media Information')
          expect(organization.reload.partner_form_fields).to eq([])
        end
      end

      context "can disable if the org does NOT use single step invite and approve partner process" do
        let(:update_param) { { organization: { one_step_partner_invite: false } } }
        it "works" do
          subject
          expect(response).to redirect_to(organization_path)
          follow_redirect!
          expect(response.body).to include("No")
        end
      end

      context "can enable if the org does NOT receive emails when a partner makes a request" do
        let(:update_param) { { organization: { receive_email_on_requests: true } } }
        it "works" do
          subject
          expect(response).to redirect_to(organization_path)
          follow_redirect!
          expect(response.body).to include("Receive email when Partner makes a Request?</h6>
              <p>
                Yes
              </p>")
        end
      end

      context "can enable if the org uses single step invite and approve partner process" do
        let(:update_param) { { organization: { one_step_partner_invite: true } } }
        it "works" do
          subject
          expect(response).to redirect_to(organization_path)
          follow_redirect!
          expect(response.body).to include("Yes")
        end
      end
    end

    describe "POST #promote_to_org_admin" do
      context "promoting a user" do
        include_examples "promote to admin check", :user, :non_super_admin
      end

      context "promoting a super admin user" do
        include_examples "promote to admin check", :super_admin, :non_super_admin
      end
    end

    describe "POST #demote_to_user" do
      context "demoting a user" do
        include_examples "demote to user check", :organization_admin, :non_super_admin
      end

      context "demoting a super admin user" do
        include_examples "demote to user check", :super_admin_org_admin, :non_super_admin
      end
    end

    describe "POST #remove_user" do
      context "removing a user" do
        include_examples "remove user check", :user, :non_super_admin
      end

      context "removing a super admin user" do
        include_examples "remove user check", :super_admin, :non_super_admin
      end

      context "when user is not an org user" do
        let(:user) { create(:user, organization: create(:organization)) }

        it 'raises an error' do
          post remove_user_organization_path(user_id: user.id)

          expect(response).to be_not_found
        end
      end
    end

    context "when attempting to access a different organization" do
      let(:other_organization) { create(:organization) }
      let(:other_organization_params) do
        { organization_id: other_organization.id }
      end

      describe "GET #show" do
        before { get organization_path(other_organization_params) }

        it "shows your own anyway" do
          expect(response.body).to include(organization.name)
        end
      end

      describe "GET #edit" do
        before { get edit_organization_path(other_organization_params) }

        it "shows your own anyway" do
          expect(response.body).to include(organization.name)
        end
      end

      describe "POST #promote_to_org_admin" do
        let(:other_user) { create(:user, organization: other_organization, name: "Wrong User") }

        subject { post promote_to_org_admin_organization_path(user_id: other_user.id) }

        it "redirects after update" do
          subject
          expect(response).to have_http_status(:not_found)
          expect(other_user.reload.has_role?(Role::ORG_ADMIN, organization)).to eq(false)
          expect(other_user.reload.has_role?(Role::ORG_ADMIN, other_organization)).to eq(false)
        end
      end
    end
  end

  context 'When signed in as a super admin' do
    before do
      sign_in(super_admin_org_admin)
    end

    describe "POST #promote_to_org_admin" do
      context "promoting a user" do
        include_examples "promote to admin check", :user, :super_admin
      end

      context "promoting a super admin user" do
        include_examples "promote to admin check", :super_admin, :super_admin
      end
    end

    describe "POST #demote_to_user" do
      context "demoting a user" do
        include_examples "demote to user check", :organization_admin, :super_admin
      end

      context "demoting a super admin user" do
        include_examples "demote to user check", :super_admin_org_admin, :super_admin
      end
    end

    describe "POST #remove_user" do
      context "removing a user" do
        include_examples "remove user check", :user, :super_admin
      end

      context "removing a super admin user" do
        include_examples "remove user check", :super_admin, :super_admin
      end

      context "when user is not an org user" do
        let(:user) { create(:user, organization: create(:organization)) }

        it 'raises an error' do
          # Explicitly specify the organization_id, as current_organization will not
          # be set for super admins
          post remove_user_organization_path(user_id: user.id, organization_id: organization.id)

          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
