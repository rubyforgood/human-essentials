require_relative("../support/distribution_pdf_helper")

RSpec.configure do |c|
  c.include DistributionPDFHelper
end

describe DistributionPdf do
  let(:organization) {
    create(:organization,
      name: "Essentials Bank 1",
      street: "1500 Remount Road",
      city: "Front Royal",
      state: "VA",
      zipcode: "22630",
      email: "email1@example.com")
  }

  let(:storage_location) { create(:storage_location, organization: organization) }

  let(:item1) { create(:item, name: "Item 1", package_size: 50, value_in_cents: 100) }
  let(:item2) { create(:item, name: "Item 2", value_in_cents: 200) }
  let(:item3) { create(:item, name: "Item 3", value_in_cents: 300) }
  let(:item4) { create(:item, name: "Item 4", package_size: 25, value_in_cents: 400) }

  describe "pdf item and column displays" do
    let(:org_hiding_packages_and_values) {
      create(:organization, name: DEFAULT_TEST_ORGANIZATION_NAME,
        hide_value_columns_on_receipt: true, hide_package_column_on_receipt: true)
    }
    let(:org_hiding_packages) { create(:organization, name: DEFAULT_TEST_ORGANIZATION_NAME, hide_package_column_on_receipt: true) }
    let(:org_hiding_values) { create(:organization, name: DEFAULT_TEST_ORGANIZATION_NAME, hide_value_columns_on_receipt: true) }

    let(:distribution) { create(:distribution, organization: organization, storage_location: storage_location) }

    before(:each) do
      create_line_items_request(distribution)
    end

    specify "#request_data" do
      results = described_class.new(organization, distribution).request_data
      expect(results).to eq([
        ["Items Received", "Requested", "Received", "Value/item", "In-Kind Value Received", "Packages"],
        ["Item 1", "", 50, "$1.00", "$50.00", "1"],
        ["Item 2", 30, 100, "$2.00", "$200.00", nil],
        ["Item 3", 50, "", "$3.00", nil, nil],
        ["Item 4", 120, "", "$4.00", nil, nil],
        ["", "", "", "", ""],
        ["Total Items Received", 200, 150, "", "$250.00", ""]
      ])
    end

    specify "#non_request_data" do
      results = described_class.new(organization, distribution).non_request_data
      expect(results).to eq([
        ["Items Received", "Value/item", "In-Kind Value", "Quantity", "Packages"],
        ["Item 1", "$1.00", "$50.00", 50, "1"],
        ["Item 2", "$2.00", "$200.00", 100, nil],
        ["", "", "", "", ""],
        ["Total Items Received", "", "$250.00", 150, ""]
      ])
    end

    context "with request data" do
      describe "#hide_columns" do
        it "hides value and package columns when true on organization" do
          pdf = described_class.new(org_hiding_packages_and_values, distribution)
          data = pdf.request_data
          pdf.hide_columns(data)
          expect(data).to eq([
            ["Items Received", "Requested", "Received"],
            ["Item 1", "", 50],
            ["Item 2", 30, 100],
            ["Item 3", 50, ""],
            ["Item 4", 120, ""],
            ["", "", ""],
            ["Total Items Received", 200, 150]
          ])
        end

        it "hides value columns when true on organization" do
          pdf = described_class.new(org_hiding_values, distribution)
          data = pdf.request_data
          pdf.hide_columns(data)
          expect(data).to eq([
            ["Items Received", "Requested", "Received", "Packages"],
            ["Item 1", "", 50, "1"],
            ["Item 2", 30, 100, nil],
            ["Item 3", 50, "", nil],
            ["Item 4", 120, "", nil],
            ["", "", ""],
            ["Total Items Received", 200, 150, ""]
          ])
        end
      end
    end

    context "with non request data" do
      it "hides value and package columns when true on organization" do
        pdf = described_class.new(org_hiding_packages_and_values, distribution)
        data = pdf.request_data
        pdf.hide_columns(data)
        expect(data).to eq([
          ["Items Received", "Requested", "Received"],
          ["Item 1", "", 50],
          ["Item 2", 30, 100],
          ["Item 3", 50, ""],
          ["Item 4", 120, ""],
          ["", "", ""],
          ["Total Items Received", 200, 150]
        ])
      end

      it "hides value columns when true on organization" do
        pdf = described_class.new(org_hiding_values, distribution)
        data = pdf.request_data
        pdf.hide_columns(data)
        expect(data).to eq([
          ["Items Received", "Requested", "Received", "Packages"],
          ["Item 1", "", 50, "1"],
          ["Item 2", 30, 100, nil],
          ["Item 3", 50, "", nil],
          ["Item 4", 120, "", nil],
          ["", "", ""],
          ["Total Items Received", 200, 150, ""]
        ])
      end
    end
    context "regardles of request data" do
      describe "#hide_columns" do
        it "hides package column when true on organization" do
          pdf = described_class.new(org_hiding_packages, distribution)
          data = pdf.request_data
          pdf.hide_columns(data)
          expect(data).to eq([
            ["Items Received", "Requested", "Received", "Value/item", "In-Kind Value Received"],
            ["Item 1", "", 50, "$1.00", "$50.00"],
            ["Item 2", 30, 100, "$2.00", "$200.00"],
            ["Item 3", 50, "", "$3.00", nil],
            ["Item 4", 120, "", "$4.00", nil],
            ["", "", "", "", ""],
            ["Total Items Received", 200, 150, "", "$250.00"]
          ])
        end
      end
    end
  end

  describe "address pdf output" do
    let(:partner) {
      create(:partner, :uninvited, without_profile: true,
        name: "Leslie Sue",
        organization: organization)
    }
    let(:profile_name) { "Jaqueline Kihn DDS" }
    let(:profile_email) { "van@durgan.example" }
    # there is a helper test at the bottom to regenerate these PDFs easily
    let(:expected_pickup_file_path) { Rails.root.join("spec", "fixtures", "files", "distribution_pickup.pdf") }
    let(:expected_pickup_file) { IO.binread(expected_pickup_file_path) }
    let(:expected_same_address_file_path) { Rails.root.join("spec", "fixtures", "files", "distribution_same_address.pdf") }
    let(:expected_same_address_file) { IO.binread(expected_same_address_file_path) }
    let(:expected_different_address_file_path) { Rails.root.join("spec", "fixtures", "files", "distribution_program_address.pdf") }
    let(:expected_different_address_file) { IO.binread(expected_different_address_file_path) }

    context "when the partner has no addresses" do
      before(:each) do
        create(:partner_profile,
          partner_id: partner.id,
          primary_contact_name: profile_name,
          primary_contact_email: profile_email,
          address1: "",
          address2: "",
          city: "",
          state: "",
          zip_code: "",
          program_address1: "",
          program_address2: "",
          program_city: "",
          program_state: "",
          program_zip_code: "")
      end
      it "doesn't print any address if the delivery type is pickup" do
        compare_pdf(create_dist(:pick_up), expected_pickup_file)
      end
      it "doesn't print any address if the delivery type is delivery" do
        compare_pdf(create_dist(:delivery), expected_pickup_file)
      end
      it "doesn't print any address if the delivery type is shipped" do
        compare_pdf(create_dist(:shipped), expected_pickup_file)
      end
    end
    context "when the partner doesn't have a different program address" do
      before(:each) do
        create_profile_without_program_address
      end
      it "prints the address if the delivery type is delivery" do
        compare_pdf(create_dist(:delivery), expected_same_address_file)
      end
      it "prints the address if the delivery type is shipped" do
        compare_pdf(create_dist(:shipped), expected_same_address_file)
      end
      it "doesn't print the address if the delivery type is pickup" do
        compare_pdf(create_dist(:pick_up), expected_pickup_file)
      end
    end
    context "when the partner has a different program/delivery address" do
      before(:each) do
        create_profile_with_program_address
      end
      it "prints the delivery address if the delivery type is delivery" do
        compare_pdf(create_dist(:delivery), expected_different_address_file)
      end
      it "prints the delivery address if the delivery type is shipped" do
        compare_pdf(create_dist(:shipped), expected_different_address_file)
      end
      it "doesn't print any address if the delivery type is pickup" do
        compare_pdf(create_dist(:pick_up), expected_pickup_file)
      end
    end
    # this test is a helper function to regenerate expected PDFs, only commit with it skipped
    # this is written as a RSpec so we don't have duplicated code for setting up the RSpec test environment
    # call this test to generate PDFs from terminal by
    #   1) setting to `if true`
    #   2) calling the test's line number from terminal e.g. `bundle exec rspec spec/pdfs/distribution_pdf_spec.rb:228`
    #   3) disable the test afterwards by setting to `if false`
    # rubocop:disable Lint/LiteralAsCondition
    if false
      # rubocop:enable Lint/LiteralAsCondition
      it "skip this helper function for regenerating the expected pdfs", type: :request do
        user = create(:user, organization: organization)
        sign_in(user)

        profile = create_profile_without_program_address

        dist = create_dist(:pick_up)
        get print_distribution_path(dist)
        File.binwrite(expected_pickup_file_path, response.body)
        dist.destroy

        dist = create_dist(:shipped)
        get print_distribution_path(dist)
        File.binwrite(expected_same_address_file_path, response.body)
        dist.destroy

        profile.destroy
        create_profile_with_program_address

        dist = create_dist(:shipped)
        get print_distribution_path(dist)
        File.binwrite(expected_different_address_file_path, response.body)

        raise "Do not commit this helper function"
      end
    end
  end
end
