RSpec.describe "Partners", type: :request do
  # Specify partner_form_fields for the sake of brevity in the csv output of GET #index.
  let(:organization) { create(:organization, partner_form_fields: ["media_information"]) }
  let(:user) { create(:user, organization: organization) }

  before do
    sign_in(user)
  end

  describe "GET #index" do
    subject do
      get partners_path(format: response_format)
      response
    end

    context "html" do
      let(:response_format) { 'html' }

      let!(:partner) { create(:partner, organization: organization) }

      it { is_expected.to be_successful }

      include_examples "restricts access to organization users/admins"
    end

    context "csv" do
      let(:response_format) { 'csv' }

      let!(:partner) do
        create(:partner, name: "Leslie Sue", email: "leslie@sue.com", status: :approved, organization:, notes: "Some notes", without_profile: true)
      end
      let!(:profile) do
        create(:partner_profile,
          partner: partner,
          agency_type: :other, # Columns from the agency_information partial
          other_agency_type: "Another Agency Name",
          agency_mission: "agency_mission",
          address1: "4744 McDermott Mountain",
          address2: "333 Never land street",
          city: "Lake Shoshana",
          state: "ND",
          zip_code: "09980-7010",
          program_address1: "program_address1",
          program_address2: "program_address2",
          program_city: "program_city",
          program_state: "program_state",
          program_zip_code: 12345,
          website: "bosco.example", # Columns from the media_information partial
          facebook: "facebook",
          twitter: "twitter",
          instagram: "instagram",
          no_social_media_presence: false,
          enable_child_based_requests: true, # Columns from the partner_settings partial
          enable_individual_requests: true,
          enable_quantity_based_requests: true)
      end

      let(:expected_headers) {
        [
          "Agency Name", # Technically not part of the agency_information partial, but comes at the start of the export
          "Agency Email",
          "Notes",
          "Agency Type", # Columns from the agency_information partial
          "Other Agency Type",
          "Agency Mission",
          "Agency Address",
          "Agency City",
          "Agency State",
          "Agency Zip Code",
          "Program/Delivery Address",
          "Program City",
          "Program State",
          "Program Zip Code",
          "Agency Website", # Columns from the media_information partial
          "Facebook",
          "Twitter",
          "Instagram",
          "No Social Media Presence",
          "Quantity-based Requests", # Columns from the agency_information partial
          "Child-based Requests",
          "Individual Requests",
          "Providing Diapers", # Technically not part of the partner_settings partial, but comes at the end of the export
          "Providing Period Supplies"
        ]
      }

      let(:expected_values) {
        [
          "Leslie Sue", # Technically not part of the agency_information partial, but comes at the start of the export
          "leslie@sue.com",
          "Some notes",
          I18n.t("partners_profile.other"), # Columns from the agency_information partial
          "Another Agency Name",
          "agency_mission",
          "4744 McDermott Mountain, 333 Never land street",
          "Lake Shoshana",
          "ND",
          "09980-7010",
          "program_address1, program_address2",
          "program_city",
          "program_state",
          "12345",
          "bosco.example", # Columns from the media_information partial
          "facebook",
          "twitter",
          "instagram",
          "false",
          "true", # Columns from the partner_settings partial
          "true",
          "true",
          "N", # Technically not part of the partner_settings partial, but comes at the end of the export
          "N"
        ]
      }

      it { is_expected.to be_successful }
      it "returns the expected headers" do
        get partners_path(partner, format: response_format)

        csv = CSV.parse(response.body)

        expect(csv[0]).to eq(expected_headers)
      end

      context "with missing partner info" do
        it "returns a CSV with correct data" do
          partner.update(profile: create(
            :partner_profile,
            website: nil,
            primary_contact_name: nil,
            primary_contact_email: nil
          ))

          # The agency_information and settings sections contain information stored on the partner and not the
          # profile, so they won't be completely empty
          expected_values = [
            "Leslie Sue",
            "leslie@sue.com",
            "Some notes",
            "", # Columns from the agency_information partial
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "", # Columns from the media_information partial
            "",
            "",
            "",
            "",
            "true", # Columns from the partner_settings partial
            "true",
            "true",
            "N",
            "N"
          ]

          get partners_path(partner, format: response_format)
          csv = CSV.parse(response.body)
          expect(csv[1]).to eq(expected_values)
        end
      end

      it "returns a CSV with correct data" do
        get partners_path(partner, format: response_format)

        csv = CSV.parse(response.body)

        expect(csv[1]).to eq(expected_values)
      end

      it "returns only active partners by default" do
        partner.update(status: :deactivated)

        get partners_path(partner, format: response_format)
        csv = CSV.parse(response.body)
        # Expect no parner rows in csv
        expect(csv[0]).to eq(expected_headers)
        expect(csv[1]).to eq(nil)
      end

      context "with served counties" do
        before do
          organization.update(partner_form_fields: organization.partner_form_fields += ["area_served"])
        end

        it "returns them in correct order" do
          county_1 = create(:county, name: "High County, Maine", region: "Maine")
          county_2 = create(:county, name: "laRue County, Louisiana", region: "Louisiana")
          county_3 = create(:county, name: "Ste. Anne County, Louisiana", region: "Louisiana")
          create(:partners_served_area, partner_profile: profile, county: county_1, client_share: 50)
          create(:partners_served_area, partner_profile: profile, county: county_2, client_share: 40)
          create(:partners_served_area, partner_profile: profile, county: county_3, client_share: 10)

          get partners_path(partner, format: response_format)

          csv = CSV.parse(response.body, headers: true)

          expect(csv[0]["Area Served"]).to eq("laRue County, Louisiana; Ste. Anne County, Louisiana; High County, Maine")
        end
      end

      context "with multiple partners do" do
        let!(:partner_2) do
          create(:partner, name: "Jane Doe", email: "jane@doe.com", status: :invited, organization:, notes: "Some notes", without_profile: true)
        end
        let!(:profile_2) do
          create(:partner_profile,
            partner: partner_2,
            agency_type: :other, # Columns from the agency_information partial
            other_agency_type: "Another Agency Name",
            agency_mission: "agency_mission_2",
            address1: "4744 McDermott Mountain",
            address2: "333 Never land street",
            city: "Lake Shoshana",
            state: "ND",
            zip_code: "09980-7010",
            program_address1: "program_address1_2",
            program_address2: "program_address2_2",
            program_city: "program_city_2",
            program_state: "program_state_2",
            program_zip_code: 12345,
            website: "bosco.example", # Columns from the media_information partial
            facebook: "facebook_2",
            twitter: "twitter_2",
            instagram: "instagram_2",
            no_social_media_presence: false,
            enable_child_based_requests: true, # Columns from the partner_settings partial
            enable_individual_requests: true,
            enable_quantity_based_requests: true)
        end

        it "orders partners alphabetically" do
          get partners_path(partner, format: response_format)

          csv = CSV.parse(response.body)

          expect(csv[1]).to eq(
            [
              "Jane Doe",
              "jane@doe.com",
              "Some notes",
              I18n.t("partners_profile.other"), # Columns from the agency_information partial
              "Another Agency Name",
              "agency_mission_2",
              "4744 McDermott Mountain, 333 Never land street",
              "Lake Shoshana",
              "ND",
              "09980-7010",
              "program_address1_2, program_address2_2",
              "program_city_2",
              "program_state_2",
              "12345",
              "bosco.example", # Columns from the media_information partial
              "facebook_2",
              "twitter_2",
              "instagram_2",
              "false",
              "true", # Columns from the partner_settings partial
              "true",
              "true",
              "N",
              "N"
            ]
          )
        end
      end
    end
  end

  describe 'POST #create' do
    subject { -> { post partners_path(partner_attrs) } }

    context 'when given valid partner attributes in the params' do
      let(:partner_attrs) do
        {
          partner: FactoryBot.attributes_for(:partner)
        }
      end

      it 'should create a new Partner record' do
        expect { subject.call }.to change { Partner.all.count }.by(1)
      end

      it 'should create a new Partners::Profile record' do
        expect { subject.call }.to change { Partners::Profile.all.count }.by(1)
      end

      it 'redirect to the partners index page' do
        subject.call
        expect(response).to redirect_to(partners_path)
      end
    end

    context 'when given invalid partner attributes in the params' do
      let(:partner_attrs) do
        {
          partner: {
            name: nil
          }
        }
      end

      it 'should not create a new Partner record' do
        expect { subject.call }.not_to change { Partner.all.count }
      end

      it 'should not create a new Partners::Profile record' do
        expect { subject.call }.not_to change { Partners::Profile.all.count }
      end

      it 'should display the error message' do
        subject.call
        expect(response.body).to include("Failed to add partner due to: ")
      end
    end
  end

  describe "GET #show" do
    subject do
      get partner_path(partner, format: response_format)
      response
    end

    let(:partner) do
      partner = create(:partner, organization: organization, status: :approved)
      partner.distributions << create(:distribution, :with_items, :past, item_quantity: 1231)
      partner
    end
    let!(:family1) { FactoryBot.create(:partners_family, guardian_zip_code: '45612-123', partner: partner) }
    let!(:family2) { FactoryBot.create(:partners_family, guardian_zip_code: '45612-126', partner: partner) }
    let!(:family3) { FactoryBot.create(:partners_family, guardian_zip_code: '45612-123', partner: partner) }

    let!(:child1) { FactoryBot.create_list(:partners_child, 2, family: family1) }
    let!(:child2) { FactoryBot.create_list(:partners_child, 2, family: family3) }

    let(:expected_impact_metrics) do
      {
        families_served: 3,
        children_served: 4,
        family_zipcodes: 2,
        family_zipcodes_list: contain_exactly("45612-126", "45612-123") # order of zipcodes not guaranteed
      }
    end

    context "html" do
      let(:response_format) { 'html' }

      it "displays distribution scheduled date" do
        subject
        partner.distributions.each do |distribution|
          expect(subject.body).to include(distribution.issued_at.strftime("%m/%d/%Y"))
          expect(subject.body).to_not include(distribution.created_at.strftime("%m/%d/%Y"))
        end
      end

      context "without org admin" do
        it 'should not show the manage users button' do
          expect(subject).to be_successful
          expect(subject.body).not_to include("Manage Users")
        end
      end

      context "with org admin" do
        before(:each) do
          user.add_role(Role::ORG_ADMIN, organization)
        end
        it 'should show the manage users button' do
          expect(subject).to be_successful
          expect(subject.body).to include("Manage Users")
        end
      end

      context "when the partner is invited" do
        it "includes impact metrics" do
          subject
          expect(assigns[:impact_metrics]).to match(expected_impact_metrics)
        end
      end

      context "when the partner is uninvited" do
        let(:partner) { create(:partner, organization: organization, status: :uninvited) }

        it "does not include impact metrics" do
          subject
          expect(assigns[:impact_metrics]).not_to be_present
        end

        it 'does not show the delete button' do
          expect(subject).not_to include('Delete')
        end

        context 'when the partner has no users' do
          # see the deletable? method which is tested separately in the partner model spec
          it 'shows the delete button' do
            partner.users.each(&:destroy)
            expect(subject.body).to include('Delete')
          end
        end
      end
    end

    context "csv" do
      let(:response_format) { 'csv' }

      it { is_expected.to be_successful }
    end
  end

  describe "GET #new" do
    it "returns http success" do
      get new_partner_path
      expect(response).to be_successful
    end
  end

  describe "GET #edit" do
    it "returns http success" do
      get edit_partner_path(id: create(:partner, organization: organization))
      expect(response).to be_successful
    end
  end

  describe "POST #import_csv" do
    let(:model_class) { Partner }
    let!(:outside_organization) { create(:organization) }
    let!(:invalid_storage_location) { create(:storage_location, name: 'invalid', organization: outside_organization) }
    let!(:valid_storage_location) { create(:storage_location, organization: organization) }

    context "with a csv file" do
      let(:file) { fixture_file_upload("partners_with_six_fields.csv", "text/csv") }
      subject { post import_csv_partners_path, params: { file: file } }

      it "invokes .import_csv" do
        expect(model_class).to respond_to(:import_csv).with(2).arguments
      end

      it "redirects to :index" do
        subject
        expect(response).to be_redirect
      end

      it "presents a flash notice message" do
        subject
        expect(response).to have_notice "#{model_class.name.underscore.humanize.pluralize} were imported successfully!"
      end
    end

    context "without a csv file" do
      it "redirects to :index" do
        post import_csv_partners_path
        expect(response).to be_redirect
      end

      it "presents a flash error message" do
        post import_csv_partners_path
        expect(response).to have_error "No file was attached!"
      end
    end

    context "csv file with wrong headers" do
      let(:file) { fixture_file_upload("wrong_headers.csv", "text/csv") }
      subject { post import_csv_partners_path, params: { file: file } }

      it "redirects to :index" do
        subject
        expect(response).to be_redirect
      end

      it "presents a flash error message" do
        subject
        expect(response).to have_error "Check headers in file!"
      end
    end

    context "csv file with send_reminders header and field missing" do
      let(:file) { fixture_file_upload("partners_missing_send_reminders_field_and_header.csv", "text/csv") }
      subject { post import_csv_partners_path, params: { file: file } }

      it "invokes .import_csv" do
        expect(model_class).to respond_to(:import_csv).with(2).arguments
      end

      it "redirects to :index" do
        subject
        expect(response).to be_redirect
      end

      it "defaults send_reminders to false" do
        subject
        partner = Partner.find_by(name: "Partner 51")
        expect(partner.send_reminders).to be(false)
      end
    end

    context "csv file with send_reminders field missing" do
      let(:file) { fixture_file_upload("partners_missing_send_reminders_field.csv", "text/csv") }
      subject { post import_csv_partners_path, params: { file: file } }

      it "invokes .import_csv" do
        expect(model_class).to respond_to(:import_csv).with(2).arguments
      end

      it "redirects to :index" do
        subject
        expect(response).to be_redirect
      end

      it "defaults send_reminders to false" do
        subject
        partner = Partner.find_by(name: "Partner 51")
        expect(partner.send_reminders).to be(false)
      end
    end

    context "csv file with invalid email address" do
      let(:file) { fixture_file_upload("partners_with_invalid_email.csv", "text/csv") }
      subject { post import_csv_partners_path, params: { file: file } }

      it "invokes .import_csv" do
        expect(model_class).to respond_to(:import_csv).with(2).arguments
      end

      it "redirects to :index" do
        subject
        expect(response).to be_redirect
      end

      it "presents a flash notice message displaying the import errors" do
        subject
        expect(response).to have_error(/The following #{model_class.name.underscore.humanize.pluralize} did not import successfully:/)
        expect(response).to have_error(/Partner 2: Email is invalid/)
      end
    end

    context "csv file with default storage location header and field missing" do
      let(:file) { fixture_file_upload("partners_missing_default_storage_location_field_and_header.csv", "text/csv") }
      subject { post import_csv_partners_path, params: { file: file } }

      it "invokes .import_csv" do
        expect(model_class).to respond_to(:import_csv).with(2).arguments
      end

      it "redirects to :index" do
        subject
        expect(response).to be_redirect
      end

      it "presents a flash notice message" do
        subject
        expect(response).to have_notice "#{model_class.name.underscore.humanize.pluralize} were imported successfully!"
      end
    end

    context "csv file with default storage location field missing" do
      let(:file) { fixture_file_upload("partners_missing_default_storage_location_field.csv", "text/csv") }
      subject { post import_csv_partners_path, params: { file: file } }

      it "invokes .import_csv" do
        expect(model_class).to respond_to(:import_csv).with(2).arguments
      end

      it "redirects to :index" do
        subject
        expect(response).to be_redirect
      end

      it "presents a flash notice message" do
        subject
        expect(response).to have_notice "#{model_class.name.underscore.humanize.pluralize} were imported successfully!"
      end
    end

    context "csv file with default storage location, email preferences, quota, and notes" do
      let(:file) { fixture_file_upload("partners_with_six_fields.csv", "text/csv") }
      subject { post import_csv_partners_path, params: { file: file } }

      it "invokes .import_csv" do
        expect(model_class).to respond_to(:import_csv).with(2).arguments
      end

      it "redirects to :index" do
        subject
        expect(response).to be_redirect
      end

      it "presents a flash notice message" do
        subject
        expect(response).to have_notice "#{model_class.name.underscore.humanize.pluralize} were imported successfully!"
      end
    end

    context "csv file with an invalid storage location" do
      let!(:current_organization) { create(:organization) }
      let!(:outside_organization) { create(:organization) }
      let!(:outside_storage_location) { create(:storage_location, name: "Invalid", organization: outside_organization) }
      let(:file) { fixture_file_upload("partners_with_six_fields_invalid_location.csv", "text/csv") }
      before do
        allow(controller).to receive(:current_organization).and_return(current_organization)
      end

      subject { post import_csv_partners_path, params: { file: file } }

      it "presents a flash error message" do
        subject
        expect(flash[:alert]).to be_present
        expect(flash[:alert]).to match(/The following Partners imported with warnings/)
      end
    end

    context "csv file with a valid all-caps storage location" do
      let(:file) { fixture_file_upload("partners_with_six_fields.csv", "text/csv") }
      subject { post import_csv_partners_path, params: { file: file } }

      it "invokes .import_csv" do
        expect(model_class).to respond_to(:import_csv).with(2).arguments
      end

      it "redirects to :index" do
        subject
        expect(response).to be_redirect
      end

      it "presents a flash notice message" do
        subject
        expect(response).to have_notice "#{model_class.name.underscore.humanize.pluralize} were imported successfully!"
      end
    end

    context "csv file with a blank line at the file's bottom" do
      let(:file) { fixture_file_upload("partners_with_final_line_blank.csv", "text/csv") }
      subject { post import_csv_partners_path, params: { file: file } }

      it "redirects to :index" do
        subject
        expect(response).to be_redirect
      end

      it "presents a flash notice message" do
        subject
        expect(response).to have_notice "#{model_class.name.underscore.humanize.pluralize} were imported successfully!"
      end
    end
  end

  describe "POST #create" do
    context "successful save" do
      partner_params = { partner: { name: "A Partner", email: "partner@example.com", send_reminders: "false" } }

      it "creates a new partner" do
        post partners_path(partner_params)
        expect(response).to have_http_status(:found)
      end

      it "redirects to #index" do
        post partners_path(partner_params)
        expect(response).to redirect_to(partners_path)
      end
    end

    context "unsuccessful save due to empty params" do
      partner_params = { partner: { name: "", email: "" } }

      it "renders :new" do
        post partners_path(partner_params)
        expect(response).to render_template(:new)
      end
    end
  end

  describe "POST #update" do
    context "successful save" do
      partner_params = { name: "A Partner", email: "partner@example.com", send_reminders: "false" }

      it "update partner" do
        partner = create(:partner, organization: organization)
        put partner_path(id: partner, partner: partner_params)
        expect(response).to have_http_status(:found)
      end

      it "redirects to #show" do
        partner = create(:partner, organization: organization)
        put partner_path(id: partner, partner: partner_params)
        expect(response).to redirect_to(partner_path(partner))
      end
    end

    context "unsuccessful save due to empty params" do
      partner_params = { name: "", email: "" }

      it "renders :edit" do
        partner = create(:partner, organization: organization)
        put partner_path(id: partner, partner: partner_params)
        expect(response).to render_template(:edit)
      end
    end
  end

  describe "DELETE #destroy" do
    it "redirects to #index" do
      delete partner_path(id: create(:partner, organization: organization))
      expect(response).to redirect_to(partners_path)
    end
  end

  describe "POST #invite" do
    let(:partner) { create(:partner, organization: organization) }
    before do
      service = instance_double(PartnerInviteService, call: nil, errors: [])
      allow(PartnerInviteService).to receive(:new).and_return(service)
    end

    it "sends the invite" do
      post invite_partner_path(id: partner.id)
      expect(PartnerInviteService).to have_received(:new).with(partner: partner, force: true)
      expect(response).to have_http_status(:found)
    end
  end

  describe "PUT #deactivate" do
    let(:partner) { create(:partner, organization: organization, status: "approved") }

    context "when the partner successfully deactivates" do
      it "changes the partner status to deactivated and redirects with flash" do
        put deactivate_partner_path(id: partner.id)

        expect(partner.reload.status).to eq("deactivated")
        expect(response).to redirect_to(partners_path)
        expect(flash[:notice]).to eq("#{partner.name} successfully deactivated!")
      end
    end
  end

  describe "GET #approve_application" do
    subject { -> { get approve_application_partner_path(id: partner.id) } }
    let(:partner) { create(:partner, organization: organization) }
    let(:fake_partner_approval_service) { instance_double(PartnerApprovalService, call: -> {}) }

    before do
      allow(PartnerApprovalService).to receive(:new).with(partner: partner).and_return(fake_partner_approval_service)
    end

    context 'when the approval was successful' do
      before do
        allow(fake_partner_approval_service).to receive(:errors).and_return([])
        subject.call
      end

      it 'should redirect to the partners index page with a success flash message' do
        expect(response).to redirect_to(partners_path)
        expect(flash[:notice]).to eq("Partner approved!")
      end
    end

    context 'when the approval failed' do
      let(:fake_error_msg) { Faker::Games::ElderScrolls.dragon }
      before do
        allow(fake_partner_approval_service).to receive_message_chain(:errors, :none?).and_return(false)
        allow(fake_partner_approval_service).to receive_message_chain(:errors, :full_messages).and_return(fake_error_msg)
        subject.call
      end

      it 'should redirect to the partners index page with a failure flash message' do
        expect(response).to redirect_to(partners_path)
        expect(flash[:error]).to eq("Failed to approve partner because: #{fake_error_msg}")
      end
    end
  end

  describe "PUT #reactivate" do
    context "when the partner successfully reactivates" do
      let(:partner) { create(:partner, organization: organization, status: "deactivated") }

      it "changes the partner status to approved and redirects with flash" do
        put reactivate_partner_path(id: partner.id)

        expect(partner.reload.status).to eq('approved')
        expect(response).to redirect_to(partners_path)
        expect(flash[:notice]).to eq("#{partner.name} successfully reactivated!")
      end
    end

    context "when trying to reactivate a partner who is not deactivated " do
      let(:partner) { create(:partner, organization: organization, status: "approved") }
      it "fails to change the partner status to reactivated and redirects with flash error message" do
        put reactivate_partner_path(id: partner.id)
      end
    end
  end

  describe "POST #recertify_partner" do
    subject { -> { post recertify_partner_partner_path(id: partner.id) } }
    let(:partner) { create(:partner, organization: organization) }
    let(:fake_service) { instance_double(PartnerRequestRecertificationService, call: -> {}) }

    before do
      allow(PartnerRequestRecertificationService).to receive(:new).with(partner: partner).and_return(fake_service)
    end

    context "when the request for recertification from the partner was successful" do
      before do
        allow(fake_service).to receive_message_chain(:errors, :none?).and_return(true)
      end

      it 'should return back to the partners page with a success flash' do
        subject.call
        expect(flash[:success]).to eq("#{partner.name} recertification successfully requested!")
        expect(response).to redirect_to(partners_path)
      end
    end

    context "when the request for recertification from the partner was NOT successful" do
      before do
        allow(fake_service).to receive_message_chain(:errors, :none?).and_return(false)
      end

      it 'should return back to the partners page with a success flash' do
        subject.call
        expect(flash[:error]).to eq("#{partner.name} failed to update partner records")
        expect(response).to redirect_to(partners_path)
      end
    end
  end

  describe "POST #invite_and_approve" do
    let(:partner) { create(:partner, organization: organization) }

    context "when invitation succeeded and approval succeed" do
      before do
        fake_partner_invite_service = instance_double(PartnerInviteService, call: nil, errors: [])
        allow(PartnerInviteService).to receive(:new).and_return(fake_partner_invite_service)

        fake_partner_approval_service = instance_double(PartnerApprovalService, call: nil, errors: [])
        allow(PartnerApprovalService).to receive(:new).with(partner: partner).and_return(fake_partner_approval_service)
      end

      it "sends invitation email and approve partner in single step" do
        post invite_and_approve_partner_path(id: partner.id)

        expect(PartnerInviteService).to have_received(:new).with(partner: partner, force: true)
        expect(response).to have_http_status(:found)

        expect(PartnerApprovalService).to have_received(:new).with(partner: partner)
        expect(response).to redirect_to(partners_path)
        expect(flash[:notice]).to eq("Partner invited and approved!")
      end
    end

    context "when invitation failed" do
      let(:fake_error_msg) { Faker::Games::ElderScrolls.dragon }

      before do
        fake_partner_invite_service = instance_double(PartnerInviteService, call: nil)
        allow(PartnerInviteService).to receive(:new).with(partner: partner, force: true).and_return(fake_partner_invite_service)
        allow(fake_partner_invite_service).to receive_message_chain(:errors, :none?).and_return(false)
        allow(fake_partner_invite_service).to receive_message_chain(:errors, :full_messages).and_return(fake_error_msg)
      end

      it "should redirect to the partners index page with a notice flash message" do
        post invite_and_approve_partner_path(id: partner.id)

        expect(response).to redirect_to(partners_path)
        expect(flash[:notice]).to eq("Failed to invite #{partner.name}! #{fake_error_msg}")
      end
    end

    context "when approval fails" do
      let(:fake_error_msg) { Faker::Games::ElderScrolls.dragon }

      before do
        fake_partner_approval_service = instance_double(PartnerApprovalService, call: nil)
        allow(PartnerApprovalService).to receive(:new).with(partner: partner).and_return(fake_partner_approval_service)
        allow(fake_partner_approval_service).to receive_message_chain(:errors, :none?).and_return(false)
        allow(fake_partner_approval_service).to receive_message_chain(:errors, :full_messages).and_return(fake_error_msg)
      end

      it "should redirect to the partners index page with a notice flash message" do
        post invite_and_approve_partner_path(id: partner.id)

        expect(response).to redirect_to(partners_path)
        expect(flash[:error]).to eq("Failed to approve partner because: #{fake_error_msg}")
      end
    end
  end
end
