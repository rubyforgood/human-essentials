RSpec.describe Exports::ExportPartnersCSVService do
  describe "#generate_csv" do
    subject { CSV.parse(described_class.new(partners).generate_csv) }

    let(:organization) { create(:organization) }

    let!(:partner) { create(:partner, status: :approved, organization:, notes:, without_profile: true) }
    let!(:profile) do
      create(:partner_profile,
        partner: partner,
        primary_contact_name: contact_name,
        primary_contact_email: contact_email,
        primary_contact_phone: contact_phone,
        address1: agency_address1,
        address2: agency_address2,
        city: agency_city,
        state: agency_state,
        zip_code: agency_zipcode,
        website: agency_website,
        agency_type: agency_type,
        other_agency_type: other_agency_type)
    end
    let(:contact_name) { "Jon Ralfeo" }
    let(:contact_email) { "jon@entertainment720.com" }
    let(:contact_phone) { "1231231234" }
    let(:agency_address1) { "4744 McDermott Mountain" }
    let(:agency_address2) { "333 Never land street" }
    let(:agency_city) { "Lake Shoshana" }
    let(:agency_state) { "ND" }
    let(:agency_zipcode) { "09980-7010" }
    let(:agency_website) { "bosco.example" }
    let(:agency_type) { :other }
    let(:notes) { "Some notes" }
    let(:other_agency_type) { "Another Agency Name" }
    let(:providing_diapers) { {value: "N", index: 13} }
    let(:providing_period_supplies) { {value: "N", index: 14} }

    let(:partners) { Partner.all }

    it "should have the correct headers" do
      expected_headers = [
        "Agency Name",
        "Agency Email",
        "Agency Address",
        "Agency City",
        "Agency State",
        "Agency Zip Code",
        "Agency Website",
        "Agency Type",
        "Contact Name",
        "Contact Phone",
        "Contact Email",
        "Notes",
        "Counties Served",
        "Providing Diapers",
        "Providing Period Supplies"
      ]

      expect(subject[0]).to eq(expected_headers)
    end

    it "should have the expected info in the columns order" do
      county_1 = create(:county, name: "High County, Maine", region: "Maine")
      county_2 = create(:county, name: "laRue County, Louisiana", region: "Louisiana")
      county_3 = create(:county, name: "Ste. Anne County, Louisiana", region: "Louisiana")
      create(:partners_served_area, partner_profile: profile, county: county_1, client_share: 50)
      create(:partners_served_area, partner_profile: profile, county: county_2, client_share: 40)
      create(:partners_served_area, partner_profile: profile, county: county_3, client_share: 10)

      # county ordering is a bit esoteric -- it is human alphabetical by county within region (region is state)
      correctly_ordered_counties = "laRue County, Louisiana; Ste. Anne County, Louisiana; High County, Maine"
      expect(subject[1]).to eq([
        partner.name,
        partner.email,
        "#{agency_address1}, #{agency_address2}",
        agency_city,
        agency_state,
        agency_zipcode,
        agency_website,
        "#{I18n.t "partners_profile.other"}: #{other_agency_type}",
        contact_name,
        contact_phone,
        contact_email,
        notes,
        correctly_ordered_counties,
        providing_diapers[:value],
        providing_period_supplies[:value]
      ])
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
