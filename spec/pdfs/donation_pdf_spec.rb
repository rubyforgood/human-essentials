describe DonationPdf do
  let(:donation_site) { create(:donation_site) }
  let(:organization) { create(:organization) }
  let(:donation) { create(:donation, organization: organization, donation_site: donation_site) }
  let(:item1) { FactoryBot.create(:item, name: "Item 1", package_size: 50, value_in_cents: 100) }
  let(:item2) { FactoryBot.create(:item, name: "Item 2", value_in_cents: 200) }
  let(:item3) { FactoryBot.create(:item, name: "Item 3", value_in_cents: 300) }
  let(:item4) { FactoryBot.create(:item, name: "Item 4", package_size: 25, value_in_cents: 400) }

  let(:org_hiding_packages_and_values) do
    FactoryBot.create(:organization, name: DEFAULT_TEST_ORGANIZATION_NAME,
      hide_value_columns_on_receipt: true, hide_package_column_on_receipt: true)
  end
  let(:org_hiding_packages) { FactoryBot.create(:organization, name: DEFAULT_TEST_ORGANIZATION_NAME, hide_package_column_on_receipt: true) }
  let(:org_hiding_values) { FactoryBot.create(:organization, name: DEFAULT_TEST_ORGANIZATION_NAME, hide_value_columns_on_receipt: true) }

  before(:each) do
    create(:line_item, itemizable: donation, item: item1, quantity: 50)
    create(:line_item, itemizable: donation, item: item2, quantity: 100)
  end

  specify "#donation_data" do
    results = described_class.new(organization, donation).donation_data
    expect(results).to eq([
      ["Items Received", "Value/item", "In-Kind Value", "Quantity"],
      ["Item 1", "$1.00", "$50.00", 50],
      ["Item 2", "$2.00", "$200.00", 100],
      ["", "", "", ""],
      ["Total Items Received", "", "$250.00", 150]
    ])
  end

  context "with donation data" do
    it "hides value and package columns when true on organization" do
      pdf = described_class.new(org_hiding_packages_and_values, donation)
      data = pdf.donation_data
      pdf.hide_columns(data)
      expect(data).to eq([
        ["Items Received", "Quantity"],
        ["Item 1", 50],
        ["Item 2", 100],
        ["", ""],
        ["Total Items Received", 150]
      ])
    end
  end
end
