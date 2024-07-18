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
      create(:line_item, itemizable: distribution, item: item1, quantity: 50)
      create(:line_item, itemizable: distribution, item: item2, quantity: 100)
      create(:request, distribution: distribution,
        request_items: [{"item_id" => item2.id, "quantity" => 30},
          {"item_id" => item3.id, "quantity" => 50}, {"item_id" => item4.id, "quantity" => 120}])
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
end
