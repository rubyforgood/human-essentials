RSpec.describe Exports::ExportPartnersCSVService do
  describe "#generate_csv" do
    subject { CSV.parse(described_class.new(partners, organization).generate_csv) }

    let(:organization) { create(:organization) }

    let!(:partner) { create(:partner, name: "Jane Doe", email: "jane@doe.com", status: :approved, organization:, notes: "Some notes", without_profile: true) }
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
        founded: 2020, # Columns from the agency_stability partial
        form_990: true,
        program_name: "program_name",
        program_description: "program_description",
        program_age: 5,
        evidence_based: true,
        case_management: true,
        essentials_use: "essentials_use",
        receives_essentials_from_other: "receives_essentials_from_other",
        currently_provide_diapers: true,
        client_capacity: "client_capacity", # Columns from the organizational_capacitypartial
        storage_space: true,
        describe_storage_space: "describe_storage_space",
        sources_of_funding: "sources_of_funding", # Columns from the sources_of_funding partial
        sources_of_diapers: "sources_of_diapers",
        essentials_budget: "essentials_budget",
        essentials_funding_source: "essentials_funding_source",
        income_requirement_desc: true, # Columns from the population_served partial
        income_verification: true,
        population_black: 10,
        population_white: 10,
        population_hispanic: 10,
        population_asian: 10,
        population_american_indian: 10,
        population_island: 10,
        population_multi_racial: 10,
        population_other: 30,
        zips_served: "zips_served",
        at_fpl_or_below: 25,
        above_1_2_times_fpl: 25,
        greater_2_times_fpl: 25,
        poverty_unknown: 25,
        executive_director_name: "executive_director_name", # Columns from the contacts partial
        executive_director_phone: "executive_director_phone",
        executive_director_email: "executive_director_email",
        primary_contact_name: "Jon Ralfeo",
        primary_contact_phone: "1231231234",
        primary_contact_mobile: "4564564567",
        primary_contact_email: "jon@entertainment720.com",
        pick_up_name: "pick_up_name", # Columns from the pick_up_personpartial
        pick_up_phone: "pick_up_phone",
        pick_up_email: "pick_up_email@email.com",
        distribution_times: "distribution_times", # Columns from the agency_distribution_information partial
        new_client_times: "new_client_times",
        more_docs_required: "more_docs_required",
        enable_child_based_requests: true, # Columns from the partner_settings partial
        enable_individual_requests: true,
        enable_quantity_based_requests: true)
    end

    let(:county_1) { create(:county, name: "High County, Maine", region: "Maine") } # Information for the area_served parital
    let(:county_2) { create(:county, name: "laRue County, Louisiana", region: "Louisiana") }
    let(:county_3) { create(:county, name: "Ste. Anne County, Louisiana", region: "Louisiana") }
    let!(:served_area_1) { create(:partners_served_area, partner_profile: profile, county: county_1, client_share: 50) }
    let!(:served_area_2) { create(:partners_served_area, partner_profile: profile, county: county_2, client_share: 40) }
    let!(:served_area_3) { create(:partners_served_area, partner_profile: profile, county: county_3, client_share: 10) }

    let(:partners) { Partner.all }

    let(:optional_partials) {
      [
        :media_information,
        :agency_stability,
        :organizational_capacity,
        :sources_of_funding,
        :area_served,
        :population_served,
        :contacts,
        :pick_up_person,
        :agency_distribution_information
        ]
    }

    let(:partial_to_headers) {
      {
        agency_information: [
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
          "Program Zip Code"
        ],
        media_information: [
          "Agency Website",
          "Facebook",
          "Twitter",
          "Instagram",
          "No Social Media Presence"
        ],
        agency_stability: [
          "Year Founded",
          "Form 990 Filed",
          "Program Name",
          "Program Description",
          "Agency Age",
          "Evidence Based",
          "Case Management",
          "How Are Essentials Used",
          "Receive Essentials From Other Sources",
          "Currently Providing Diapers"
        ],
        organizational_capacity: [
          "Client Capacity",
          "Storage Space",
          "Storage Space Description"
        ],
        sources_of_funding: [
          "Sources Of Funding",
          "How do you currently obtain diapers?",
          "Essentials Budget",
          "Essentials Funding Source"
        ],
        area_served: [
          "Area Served"
        ],
        population_served: [
          "Income Requirement",
          "Verify Income",
          "% African American",
          "% Caucasian",
          "% Hispanic",
          "% Asian",
          "% American Indian",
          "% Pacific Island",
          "% Multi-racial",
          "% Other",
          "Zip Codes Served",
          "% At FPL or Below",
          "% Above 1-2 times FPL",
          "% Greater than 2 times FPL",
          "% Poverty Unknown"
        ],
        contacts: [
          "Executive Director Name",
          "Executive Director Phone",
          "Executive Director Email",
          "Primary Contact Name",
          "Primary Contact Phone",
          "Primary Contact Cell",
          "Primary Contact Email"
        ],
        pick_up_person: [
          "Pick Up Person Name",
          "Pick Up Person Phone",
          "Pick Up Person Email"
        ],
        agency_distribution_information: [
          "Distribution Times",
          "New Client Times",
          "More Docs Required"
        ],
        partner_settings: [
          "Quantity-based Requests", # Columns from the agency_information partial
          "Child-based Requests",
          "Individual Requests",
          "Providing Diapers", # Technically not part of the partner_settings partial, but comes at the end of the export
          "Providing Period Supplies"
        ]
      }
    }

    let(:partial_to_values) {
      {
        agency_information: [
          "Jane Doe", # Technically not part of the agency_information partial, but come at the start of the export
          "jane@doe.com",
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
          "12345"
        ],
        media_information: [
          "bosco.example",
          "facebook",
          "twitter",
          "instagram",
          "false"
        ],
        agency_stability: [
          "2020",
          "true",
          "program_name",
          "program_description",
          "5",
          "true",
          "true",
          "essentials_use",
          "receives_essentials_from_other",
          "true"
        ],
        organizational_capacity: [
          "client_capacity",
          "true",
          "describe_storage_space"
        ],
        sources_of_funding: [
          "sources_of_funding",
          "sources_of_diapers",
          "essentials_budget",
          "essentials_funding_source"
        ],
        area_served: [
          # county ordering is a bit esoteric -- it is human alphabetical by county within region (region is state)
          "laRue County, Louisiana; Ste. Anne County, Louisiana; High County, Maine"
        ],
        population_served: [
          "true",
          "true",
          "10",
          "10",
          "10",
          "10",
          "10",
          "10",
          "10",
          "30",
          "zips_served",
          "25",
          "25",
          "25",
          "25"
        ],
        contacts: [
          "executive_director_name",
          "executive_director_phone",
          "executive_director_email",
          "Jon Ralfeo",
          "1231231234",
          "4564564567",
          "jon@entertainment720.com"
        ],
        pick_up_person: [
          "pick_up_name",
          "pick_up_phone",
          "pick_up_email@email.com"
        ],
        agency_distribution_information: [
          "distribution_times",
          "new_client_times",
          "more_docs_required"
        ],
        partner_settings: [
          "true", # Columns from the agency_information partial
          "true",
          "true",
          "N", # Technically not part of the partner_settings partial, but comes at the end of the export
          "N"
        ]
      }
    }

    it "should have the correct headers" do
      expect(subject[0]).to eq(partial_to_headers.values.flatten)
    end

    it "should have the expected info in the columns order" do
      expect(subject[1]).to eq(partial_to_values.values.flatten)
    end

    it "should handle a partner with missing profile info" do
      # The partner_profile factory defaults to populating the no_social_media_presence, primary_contact_name, and primary_contact_email fields
      partners.first.update(profile: create(
        :partner_profile,
        no_social_media_presence: nil,
        primary_contact_name: nil,
        primary_contact_email: nil
      ))
      expected_values = []
      partial_to_values.keys.each do |partial|
        # The agency_information and settings sections contain information stored on the partner and not the
        # profile, so they won't be completely empty
        expected_values += case partial
        when :agency_information
          ["Jane Doe", "jane@doe.com", "Some notes", "", "", "", "", "", "", "", "", "", "", ""]
        when :partner_settings
          [
            "true",
            "true",
            "true",
            "N",
            "N"
          ]
        else
          Array.new(partial_to_values[partial].count) { "" }
        end
      end
      expect(subject[1]).to eq(expected_values)
    end

    it "should only export columns in profile sections the org has enabled" do
      optional_partials.each do |partial|
        organization.update(partner_form_fields: [partial])
        partners.reload
        limited_export = CSV.parse(described_class.new(partners, organization).generate_csv)
        expect(limited_export[0]).to eq(partial_to_headers[:agency_information] + partial_to_headers[partial] + partial_to_headers[:partner_settings])
        expect(limited_export[1]).to eq(partial_to_values[:agency_information] + partial_to_values[partial] + partial_to_values[:partner_settings])
      end
    end

    context "when there are no partners" do
      let(:partners) { Partner.none }
      it "should have the correct headers and no other rows" do
        expect(subject[0]).to eq(partial_to_headers.values.flatten)
        expect(subject[1]).to eq(nil)
      end

      it "should only export columns in profile sections the org has enabled" do
        optional_partials.each do |partial|
          organization.update(partner_form_fields: [partial])
          partners.reload
          limited_export = CSV.parse(described_class.new(partners, organization).generate_csv)
          expect(limited_export[0]).to eq(partial_to_headers[:agency_information] + partial_to_headers[partial] + partial_to_headers[:partner_settings])
          expect(limited_export[1]).to eq(nil)
        end
      end
    end

    context "when partner has a distribution in the last 12 months" do
      let(:distribution) { create(:distribution, partner: partner) }

      shared_examples "providing_diapers check" do |scope|
        before do
          case scope
          when :disposable_diapers
            item = create(:item, reporting_category: :disposable_diapers)
          when :cloth_diapers
            item = create(:item, reporting_category: :cloth_diapers)
          end

          create(:line_item, item: item, itemizable: distribution)
        end

        it "should have Y as providing_diapers" do
          expect(subject[1][-2]).to eq("Y")
        end
      end

      context "with a disposable item" do
        include_examples "providing_diapers check", :disposable_diapers
      end

      context "with a cloth diaper item" do
        include_examples "providing_diapers check", :cloth_diapers
      end

      context "with a period supplies item" do
        before do
          item = create(:item, reporting_category: :tampons)
          create(:line_item, item: item, itemizable: distribution)
        end

        it "should have Y as providing_period_supplies" do
          expect(subject[1][-1]).to eq("Y")
        end
      end
    end

    context "when partner only has distribution older than a 12 months" do
      let(:distribution) { create(:distribution, issued_at: (12.months.ago.beginning_of_day - 1.day), partner: partner) }
      let(:disposable_diapers_item) { create(:item, reporting_category: :disposable_diapers) }
      let(:cloth_diapers_item) { create(:item, reporting_category: :cloth_diapers) }
      let(:period_supplies_item) { create(:item, reporting_category: :tampons) }

      before do
        create(:line_item, item: disposable_diapers_item, itemizable: distribution)
        create(:line_item, item: cloth_diapers_item, itemizable: distribution)
        create(:line_item, item: period_supplies_item, itemizable: distribution)
      end

      it "should have N as providing_diapers" do
        expect(subject[1][-2]).to eq("N")
      end

      it "should have N as providing_period_supplies" do
        expect(subject[1][-1]).to eq("N")
      end
    end
  end
end
