RSpec.describe Exports::ExportPartnersCSVService do
  describe "#generate_csv" do
    subject { CSV.parse(described_class.new(partners, organization).generate_csv) }

    let(:organization) { create(:organization) }

    let!(:partner) { create(:partner, status: :approved, organization:, notes:, without_profile: true) }
    let!(:profile) do
      create(:partner_profile,
        partner: partner,
        agency_type: agency_type, # Columns from the agency_information partial
        other_agency_type: other_agency_type,
        agency_mission: agency_mission,
        address1: agency_address1,
        address2: agency_address2,
        city: agency_city,
        state: agency_state,
        zip_code: agency_zipcode,
        program_address1: program_address1,
        program_address2: program_address2,
        program_city: program_city,
        program_state: program_state,
        program_zip_code: program_zip_code,
        website: agency_website, # Columns from the media_information partial
        facebook: facebook,
        twitter: twitter,
        instagram: instagram,
        no_social_media_presence: no_social_media_presence,
        founded: founded, # Columns from the agency_stability partial
        form_990: form_990,
        program_name: program_name,
        program_description: program_description,
        program_age: program_age,
        evidence_based: evidence_based,
        case_management: case_management,
        essentials_use: essentials_use,
        receives_essentials_from_other: receives_essentials_from_other,
        currently_provide_diapers: currently_provide_diapers,
        client_capacity: client_capacity, # Columns from the organizational_capacitypartial
        storage_space: storage_space,
        describe_storage_space: describe_storage_space,
        sources_of_funding: sources_of_funding, # Columns from the sources_of_funding partial
        sources_of_diapers: sources_of_diapers,
        essentials_budget: essentials_budget,
        essentials_funding_source: essentials_funding_source,
        income_requirement_desc: income_requirement_desc, # Columns from the population_served partial
        income_verification: income_verification,
        population_black: population_black,
        population_white: population_white,
        population_hispanic: population_hispanic,
        population_asian: population_asian,
        population_american_indian: population_american_indian,
        population_island: population_island,
        population_multi_racial: population_multi_racial,
        population_other: population_other,
        zips_served: zips_served,
        at_fpl_or_below: at_fpl_or_below,
        above_1_2_times_fpl: above_1_2_times_fpl,
        greater_2_times_fpl: greater_2_times_fpl,
        poverty_unknown: poverty_unknown,
        executive_director_name: executive_director_name, # Columns from the executive_director partial
        executive_director_phone: executive_director_phone,
        executive_director_email: executive_director_email,
        primary_contact_name: contact_name,
        primary_contact_phone: contact_phone,
        primary_contact_mobile: contact_mobile,
        primary_contact_email: contact_email,
        pick_up_name: pick_up_name, # Columns from the pick_up_personpartial
        pick_up_phone: pick_up_phone,
        pick_up_email: pick_up_email,
        distribution_times: distribution_times, # Columns from the agency_distribution_information partial
        new_client_times: new_client_times,
        more_docs_required: more_docs_required,
        enable_child_based_requests: enable_child_based_requests, # Columns from the partner_settings partial
        enable_individual_requests: enable_individual_requests,
        enable_quantity_based_requests: enable_quantity_based_requests)
    end

    let(:county_1) { create(:county, name: "High County, Maine", region: "Maine") }
    let(:county_2) { create(:county, name: "laRue County, Louisiana", region: "Louisiana") }
    let(:county_3) { create(:county, name: "Ste. Anne County, Louisiana", region: "Louisiana") }
    let!(:served_area_1) { create(:partners_served_area, partner_profile: profile, county: county_1, client_share: 50) }
    let!(:served_area_2) { create(:partners_served_area, partner_profile: profile, county: county_2, client_share: 40) }
    let!(:served_area_3) { create(:partners_served_area, partner_profile: profile, county: county_3, client_share: 10) }
    let(:notes) { "Some notes" }
    let(:providing_diapers) { {value: "N", index: 14} }
    let(:providing_period_supplies) { {value: "N", index: 15} }

    let(:agency_type) { :other } # Columns from the agency_information partial
    let(:other_agency_type) { "Another Agency Name" }
    let(:agency_mission) { "agency_mission" }
    let(:agency_address1) { "4744 McDermott Mountain" }
    let(:agency_address2) { "333 Never land street" }
    let(:agency_city) { "Lake Shoshana" }
    let(:agency_state) { "ND" }
    let(:agency_zipcode) { "09980-7010" }
    let(:program_address1) { "program_address1" }
    let(:program_address2) { "program_address2" }
    let(:program_city) { "program_city" }
    let(:program_state) { "program_state" }
    let(:program_zip_code) { 12345 }
    let(:agency_website) { "bosco.example" } # Columns from the media_information partial
    let(:facebook) { "facebook" }
    let(:twitter) { "twitter" }
    let(:instagram) { "instagram" }
    let(:no_social_media_presence) { false }
    let(:founded) { 2020 } # Columns from the agency_stability partial
    let(:form_990) { true }
    let(:program_name) { "program_name" }
    let(:program_description) { "program_description" }
    let(:program_age) { 5 }
    let(:evidence_based) { true }
    let(:case_management) { true }
    let(:essentials_use) { "essentials_use" }
    let(:receives_essentials_from_other) { "receives_essentials_from_other" }
    let(:currently_provide_diapers) { true }
    let(:client_capacity) { "client_capacity" } # Columns from the organizational_capacity partial
    let(:storage_space) { true }
    let(:describe_storage_space) { "describe_storage_space" }
    let(:sources_of_funding) { "sources_of_funding" } # Columns from the sources_of_funding partial
    let(:sources_of_diapers) { "sources_of_diapers" }
    let(:essentials_budget) { "essentials_budget" }
    let(:essentials_funding_source) { "essentials_funding_source" }
    let(:income_requirement_desc) { true } # Columns from the population_served partial
    let(:income_verification) { true }
    let(:population_black) { 10 }
    let(:population_white) { 10 }
    let(:population_hispanic) { 10 }
    let(:population_asian) { 10 }
    let(:population_american_indian) { 10 }
    let(:population_island) { 10 }
    let(:population_multi_racial) { 10 }
    let(:population_other) { 30 }
    let(:zips_served) { "zips_served" }
    let(:at_fpl_or_below) { 25 }
    let(:above_1_2_times_fpl) { 25 }
    let(:greater_2_times_fpl) { 25 }
    let(:poverty_unknown) { 25 }
    let(:executive_director_name) { "executive_director_name" } # Columns from the executive_director partial
    let(:executive_director_phone) { "executive_director_phone" }
    let(:executive_director_email) { "executive_director_email" }
    let(:contact_name) { "Jon Ralfeo" }
    let(:contact_phone) { "1231231234" }
    let(:contact_mobile) { "4564564567" }
    let(:contact_email) { "jon@entertainment720.com" }
    let(:pick_up_name) { "pick_up_name" } # Columns from the pick_up_person partial
    let(:pick_up_phone) { "pick_up_phone" }
    let(:pick_up_email) { "pick_up_email@email.com" }
    let(:distribution_times) { "distribution_times" } # Columns from the agency_distribution_information partial
    let(:new_client_times) { "new_client_times" }
    let(:more_docs_required) { "more_docs_required" }
    let(:enable_quantity_based_requests) { true } # Columns from the partner_settings partial
    let(:enable_child_based_requests) { true }
    let(:enable_individual_requests) { true }

    let(:partners) { Partner.all }

    # Fields from the partner and profile that are always shown
    let(:headers_base) {
      {
        leading: [
          "Agency Name",
          "Agency Email",
          "Agency Type",
          "Agency Mission",
          "Agency Address",
          "Agency City",
          "Agency State",
          "Agency Zip Code",
          "Program/Delivery Address",
          "Program City",
          "Program State",
          "Program Zip Code",
          "Notes",
          "Counties Served",
          "Providing Diapers",
          "Providing Period Supplies"
        ],
        tailing: [
          "Quantity-based Requests",
          "Child-based Requests",
          "Individual Requests"
        ]
      }
    }

    let(:partial_to_headers) {
      {
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
          "Program Age",
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
          "Sources Of Diapers",
          "Essentials Budget",
          "Essentials Funding Source"
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
        executive_director: [
          "Executive Director Name",
          "Executive Director Phone",
          "Executive Director Email",
          "Contact Name",
          "Contact Phone",
          "Contact Cell",
          "Contact Email"
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
        ]
      }
    }

    let(:values_base) {
      {
        leading: [
          partner.name,
          partner.email,
          "#{I18n.t "partners_profile.other"}: #{other_agency_type}",
          agency_mission,
          "#{agency_address1}, #{agency_address2}",
          agency_city,
          agency_state,
          agency_zipcode,
          "#{program_address1}, #{program_address2}",
          program_city,
          program_state,
          program_zip_code.to_s,
          notes,
          # county ordering is a bit esoteric -- it is human alphabetical by county within region (region is state)
          "laRue County, Louisiana; Ste. Anne County, Louisiana; High County, Maine",
          providing_diapers[:value],
          providing_period_supplies[:value]
        ],
        tailing: [
          enable_quantity_based_requests.to_s,
          enable_child_based_requests.to_s,
          enable_individual_requests.to_s
        ]
      }
    }
    let(:partial_to_values) {
      {
        media_information: [
          agency_website,
          facebook,
          twitter,
          instagram,
          no_social_media_presence.to_s
        ],
        agency_stability: [
          founded.to_s,
          form_990.to_s,
          program_name,
          program_description,
          program_age.to_s,
          evidence_based.to_s,
          case_management.to_s,
          essentials_use,
          receives_essentials_from_other,
          currently_provide_diapers.to_s
        ],
        organizational_capacity: [
          client_capacity,
          storage_space.to_s,
          describe_storage_space
        ],
        sources_of_funding: [
          sources_of_funding,
          sources_of_diapers,
          essentials_budget,
          essentials_funding_source
        ],
        population_served: [
          income_requirement_desc.to_s,
          income_verification.to_s,
          population_black.to_s,
          population_white.to_s,
          population_hispanic.to_s,
          population_asian.to_s,
          population_american_indian.to_s,
          population_island.to_s,
          population_multi_racial.to_s,
          population_other.to_s,
          zips_served,
          at_fpl_or_below.to_s,
          above_1_2_times_fpl.to_s,
          greater_2_times_fpl.to_s,
          poverty_unknown.to_s
        ],
        executive_director: [
          executive_director_name,
          executive_director_phone,
          executive_director_email,
          contact_name,
          contact_phone,
          contact_mobile,
          contact_email
        ],
        pick_up_person: [
          pick_up_name,
          pick_up_phone,
          pick_up_email
        ],
        agency_distribution_information: [
          distribution_times,
          new_client_times,
          more_docs_required
        ]
      }
    }

    it "should have the correct headers" do
      expect(subject[0]).to eq(headers_base[:leading] + partial_to_headers.values.flatten + headers_base[:tailing])
    end

    it "should have the expected info in the columns order" do
      expect(subject[1]).to eq(values_base[:leading] + partial_to_values.values.flatten + values_base[:tailing])
    end

    it "should handle a partner with missing profile info" do
      # The partner_profile factory defaults to populating the website, primary_contact_name, and primary_contact_email fields
      partners.first.update(profile: create(
        :partner_profile,
        website: nil,
        primary_contact_name: nil,
        primary_contact_email: nil
      ))
      expected_value_leading = [
        partner.name,
        partner.email,
        "",
        "",
        ", ",
        "",
        "",
        "",
        ", ",
        "",
        "",
        "",
        notes,
        "",
        providing_diapers[:value],
        providing_period_supplies[:value]
        ]
      expected_value_tailing = [
        enable_quantity_based_requests.to_s,
        enable_child_based_requests.to_s,
        enable_individual_requests.to_s
      ]

      expect(subject[1]).to eq(expected_value_leading + Array.new(partial_to_values.values.flatten.count) { "" } + expected_value_tailing)
    end

    it "should only export columns in profile sections the org has enabled" do
      partial_to_headers.keys.each do |partial|
        organization.update(partner_form_fields: [partial])
        partners.reload
        limited_export = CSV.parse(described_class.new(partners, organization).generate_csv)
        expect(limited_export[0]).to eq(headers_base[:leading] + partial_to_headers[partial] + headers_base[:tailing])
        expect(limited_export[1]).to eq(values_base[:leading] + partial_to_values[partial] + values_base[:tailing])
      end
    end

    context "when there are no partners" do
      let(:partners) { Partner.none }
      it "should have the correct headers and no other rows" do
        expect(subject[0]).to eq(headers_base[:leading] + partial_to_headers.values.flatten + headers_base[:tailing])
        expect(subject[1]).to eq(nil)
      end

      it "should only export columns in profile sections the org has enabled" do
        partial_to_headers.keys.each do |partial|
          organization.update(partner_form_fields: [partial])
          partners.reload
          limited_export = CSV.parse(described_class.new(partners, organization).generate_csv)
          expect(limited_export[0]).to eq(headers_base[:leading] + partial_to_headers[partial] + headers_base[:tailing])
          expect(limited_export[1]).to eq(nil)
        end
      end
    end

    context "when partner has a distribution in the last 12 months" do
      let(:distribution) { create(:distribution, partner: partner) }

      shared_examples "providing_diapers check" do |scope|
        before do
          providing_diapers[:value] = "Y"

          case scope
          when :disposable
            item = create(:item, base_item: create(:base_item, category: "Diapers - Childrens"))
          when :cloth_diapers
            item = create(:item, base_item: create(:base_item, category: "Diapers - Cloth (Kids)"))
          end

          create(:line_item, item: item, itemizable: distribution)
        end

        it "should have Y as providing_diapers" do
          expect(subject[1][providing_diapers[:index]]).to eq(providing_diapers[:value])
        end
      end

      context "with a disposable item" do
        include_examples "providing_diapers check", :disposable
      end

      context "with a cloth diaper item" do
        include_examples "providing_diapers check", :cloth_diapers
      end

      context "with a period supplies item" do
        before do
          providing_period_supplies[:value] = "Y"

          item = create(:item, base_item: create(:base_item, category: "Menstrual Supplies/Items"))
          create(:line_item, item: item, itemizable: distribution)
        end

        it "should have Y as providing_period_supplies" do
          expect(subject[1][providing_period_supplies[:index]]).to eq(providing_period_supplies[:value])
        end
      end
    end

    context "when partner only has distribution older than a 12 months" do
      let(:distribution) { create(:distribution, issued_at: (12.months.ago.beginning_of_day - 1.day), partner: partner) }
      let(:disposable_diapers_item) { create(:item, base_item: create(:base_item, category: "Diapers - Childrens")) }
      let(:cloth_diapers_item) { create(:item, base_item: create(:base_item, category: "Diapers - Cloth (Kids)")) }
      let(:period_supplies_item) { create(:item, base_item: create(:base_item, category: "Menstrual Supplies/Items")) }

      before do
        create(:line_item, item: disposable_diapers_item, itemizable: distribution)
        create(:line_item, item: cloth_diapers_item, itemizable: distribution)
        create(:line_item, item: period_supplies_item, itemizable: distribution)
      end

      it "should have N as providing_diapers" do
        expect(subject[1][providing_diapers[:index]]).to eq(providing_diapers[:value])
      end

      it "should have N as providing_period_supplies" do
        expect(subject[1][providing_period_supplies[:index]]).to eq(providing_period_supplies[:value])
      end
    end
  end
end
