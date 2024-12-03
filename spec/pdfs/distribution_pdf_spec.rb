require_relative("../support/distribution_pdf_helper")
require_relative("../../lib/test_helpers/pdf_comparison_test_factory")

RSpec.configure do |c|
  c.include DistributionPDFHelper
  c.include PDFComparisonTestFactory
end

describe DistributionPdf do
  let(:storage_creation) { create_organization_storage_items }
  let(:organization) { storage_creation.organization }
  let(:storage_location) { storage_creation.storage_location }

  describe "pdf item and column displays" do
    let(:org_hiding_packages_and_values) {
      create(:organization, name: DEFAULT_TEST_ORGANIZATION_NAME,
        hide_value_columns_on_receipt: true, hide_package_column_on_receipt: true)
    }
    let(:org_hiding_packages) { create(:organization, name: DEFAULT_TEST_ORGANIZATION_NAME, hide_package_column_on_receipt: true) }
    let(:org_hiding_values) { create(:organization, name: DEFAULT_TEST_ORGANIZATION_NAME, hide_value_columns_on_receipt: true) }

    let(:distribution) { create(:distribution, organization: organization, storage_location: storage_location) }
    let(:partner) { create(:partner) }

    before(:each) do
      create_line_items_request(distribution, partner, storage_creation)
    end

    specify "#request_data with custom units feature" do
      Flipper.enable(:enable_packs)
      results = described_class.new(organization, distribution).request_data
      expect(results).to eq([
        ["Items Received", "Requested", "Received", "Value/item", "In-Kind Value Received", "Packages"],
        ["Item 1", "", 50, "$1.00", "$50.00", "1"],
        ["Item 2", 30, 100, "$2.00", "$200.00", nil],
        ["Item 3", 50, "", "$3.00", nil, nil],
        ["Item 4", "120 packs", "", "$4.00", nil, nil],
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
    let(:partner) { create_partner(organization) }
    let(:file_paths) { get_file_paths }
    let(:expected_different_address_file_path) { file_paths.expected_different_address_file_path }
    let(:expected_pickup_file_path) { file_paths.expected_pickup_file_path }
    let(:expected_same_address_file_path) { file_paths.expected_same_address_file_path }
    let(:expected_incomplete_address_file_path) { file_paths.expected_incomplete_address_file_path }
    let(:expected_no_contact_file_path) { file_paths.expected_no_contact_file_path }

    context "when the partner has no addresses" do
      before(:each) do
        create_profile_no_address(partner)
      end
      it "doesn't print any address if the delivery type is pickup" do
        compare_pdf(organization, create_dist(partner, storage_creation, :pick_up), expected_pickup_file_path)
      end
      it "doesn't print any address if the delivery type is delivery" do
        compare_pdf(organization, create_dist(partner, storage_creation, :delivery), expected_pickup_file_path)
      end
      it "doesn't print any address if the delivery type is shipped" do
        compare_pdf(organization, create_dist(partner, storage_creation, :shipped), expected_pickup_file_path)
      end
    end
    context "when the partner doesn't have a different program address" do
      before(:each) do
        create_profile_without_program_address(partner)
      end
      it "prints the address if the delivery type is delivery" do
        compare_pdf(organization, create_dist(partner, storage_creation, :delivery), expected_same_address_file_path)
      end
      it "prints the address if the delivery type is shipped" do
        compare_pdf(organization, create_dist(partner, storage_creation, :shipped), expected_same_address_file_path)
      end
      it "doesn't print the address if the delivery type is pickup" do
        compare_pdf(organization, create_dist(partner, storage_creation, :pick_up), expected_pickup_file_path)
      end
    end
    context "when the partner has a different program/delivery address" do
      before(:each) do
        create_profile_with_program_address(partner)
      end
      it "prints the delivery address if the delivery type is delivery" do
        compare_pdf(organization, create_dist(partner, storage_creation, :delivery), expected_different_address_file_path)
      end
      it "prints the delivery address if the delivery type is shipped" do
        compare_pdf(organization, create_dist(partner, storage_creation, :shipped), expected_different_address_file_path)
      end
      it "doesn't print any address if the delivery type is pickup" do
        compare_pdf(organization, create_dist(partner, storage_creation, :pick_up), expected_pickup_file_path)
      end
    end
    it "formats output correctly when the partner delivery address is incomplete" do
      create_profile_with_incomplete_address(partner)
      compare_pdf(organization, create_dist(partner, storage_creation, :delivery), expected_incomplete_address_file_path)
    end
    it "formats output correctly when the partner profile contact info does not exist" do
      create_profile_no_contact_with_program_address(partner)
      compare_pdf(organization, create_dist(partner, storage_creation, :delivery), expected_no_contact_file_path)
    end
  end
end
