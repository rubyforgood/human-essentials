RSpec.describe "Organizations", type: :request do
  let(:organization) { create(:organization) }
  let!(:user) { create(:user, organization: organization) }
  let!(:organization_admin) { create(:organization_admin, organization: organization) }
  let!(:admin_user) { create(:organization_admin, organization: organization, name: "ADMIN USER") }
  let!(:unit) { create(:unit, name: "WolfPack", organization: organization) }
  let!(:store) { create(:storage_location, organization: organization) }
  let!(:ndbn_member) { create(:ndbn_member, ndbn_member_id: "50000", account_name: "Best Place") }

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
        expect(html.text).to include("Contact Info")
        expect(html.text).to include("Default email text")
        expect(html.text).to include("Users")
        expect(html.text).to include("Short Name")
        expect(html.text).to include("URL")
        expect(html.text).to include("Partner Profile Sections")
        expect(html.text).to include("Custom Partner Invitation Message")
        expect(html.text).to include("Child Based Requests?")
        expect(html.text).to include("Individual Requests?")
        expect(html.text).to include("Quantity Based Requests?")
        expect(html.text).to include("Show Year-to-date values on distribution printout?")
        expect(html.text).to include("Logo")
        expect(html.text).to include("Use One step Partner invite and approve process?")
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
        expect(html.text).to include("Contact Info")
        expect(html.text).to include("Default email text")
        expect(html.text).to include("Users")
        expect(html.text).to include("Short Name")
        expect(html.text).to include("URL")
        expect(html.text).to include("Partner Profile Sections")
        expect(html.text).to include("Custom Partner Invitation Message")
        expect(html.text).to include("Child Based Requests?")
        expect(html.text).to include("Individual Requests?")
        expect(html.text).to include("Quantity Based Requests?")
        expect(html.text).to include("Show Year-to-date values on distribution printout?")
        expect(html.text).to include("Logo")
        expect(html.text).to include("Use One step Partner invite and approve process?")
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

      it "can re-invite a user to an organization after 7 days" do
        create(:user, name: "Ye Olde Invited User", invitation_sent_at: Time.current - 7.days)
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
          expect(response.body).to include("Custom request units used (please use singular form -- e.g. pack, not packs)")
          expect(response.body).to include "WolfPack"
        end
      end

      context "when enable_packs flipper is off" do
        it "should not display custom units and units form" do
          Flipper.disable(:enable_packs)
          get edit_organization_path
          expect(response.body).to_not include("Custom request units used (please use singular form -- e.g. pack, not packs)")
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
      subject { post promote_to_org_admin_organization_path(user_id: user.id) }

      it "runs successfully" do
        subject
        expect(user.has_role?(Role::ORG_ADMIN, organization)).to eq(true)
        expect(response).to redirect_to(organization_path)
      end
    end

    describe "POST #demote_to_user" do
      subject { post demote_to_user_organization_path(user_id: admin_user.id) }

      it "runs correctly" do
        subject
        expect(admin_user.reload.has_role?(Role::ORG_ADMIN, admin_user.organization)).to be_falsey
        expect(response).to redirect_to(organization_path)
      end
    end

    describe "POST #remove_user" do
      subject { post remove_user_organization_path(user_id: user.id) }

      context "when user is org user" do
        it "redirects after update" do
          subject
          expect(response).to redirect_to(organization_path)
        end

        it "removes the org user role" do
          expect { subject }.to change { user.has_role?(Role::ORG_USER, organization) }.from(true).to(false)
        end
      end

      context "when user is not an org user" do
        let(:user) { create(:user, organization: create(:organization)) }

        it 'raises an error' do
          subject

          expect(response).to be_not_found
        end
      end
    end

    context "when attempting to access a different organization" do
      let(:other_organization) { create(:organization) }
      let(:other_organization_params) do
        { organization_name: other_organization.to_param }
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
      sign_in(create(:super_admin, organization: organization))
    end

    describe "GET #show" do
      before { get admin_organizations_path(id: organization.id) }

      it { expect(response).to be_successful }

      it 'organization details' do
        expect(response.body).to include(organization.name)
        expect(response.body).to include(organization.email)
        expect(response.body).to include(organization.created_at.strftime("%Y-%m-%d"))
        expect(response.body).to include(organization.display_last_distribution_date)
      end
    end
  end
end
