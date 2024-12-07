describe DonationPdf do
  let(:donation_site) { create(:donation_site, name: "Site X", address: "1500 Remount Road, Front Royal, VA 22630", email: "test@example.com") }
  let(:organization) { create(:organization) }
  let(:donation) do
    create(:donation, organization: organization, donation_site: donation_site, source: Donation::SOURCES[:donation_site],
      comment: "A donation comment")
  end
  let(:product_drive) { create(:product_drive, name: "Second Best Product Drive") }
  let(:product_drive_participant) {
    create(:product_drive_participant, business_name: "A Good Place to Collect Diapers", address: "123 Front Street, Atlanta, Georgia, 54321", email: "good@place.is")
  }
  let(:product_drive_donation) do
    create(:donation, organization: organization, product_drive: product_drive, source: Donation::SOURCES[:product_drive],
      product_drive_participant: product_drive_participant, comment: "A product drive donation")
  end
  let(:product_drive_donation_without_participant) do
    create(:donation, organization: organization, product_drive: product_drive, source: Donation::SOURCES[:product_drive], comment: "A product drive donation without participant")
  end
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
    allow_any_instance_of(ProductDriveParticipant).to receive(:geocode).and_return(true)
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

  context "render pdf" do
    it "renders correctly" do
      pdf = described_class.new(organization, donation)
      pdf_test = PDF::Reader.new(StringIO.new(pdf.compute_and_render))
      expect(pdf_test.page(1).text).to include(donation_site.name)
      expect(pdf_test.page(1).text).to include(donation_site.address)
      expect(pdf_test.page(1).text).to include(donation_site.email)
      if donation.comment
        expect(pdf_test.page(1).text).to include(donation.comment)
      end
      expect(pdf_test.page(1).text).to include("Money Raised In Dollars: $0.00")
      expect(pdf_test.page(1).text).to include("Items Received")
      expect(pdf_test.page(1).text).to match(/Item 1\s+\$1\.00\s+\$50\.00\s+50/)
      expect(pdf_test.page(1).text).to match(/Item 2\s+\$2\.00\s+\$200\.00\s+100/)
      expect(pdf_test.page(1).text).to include("Total Items Received")
    end
  end

  context "product drive donation" do
    it "renders correctly" do
      pdf = described_class.new(organization, product_drive_donation)
      pdf_test = PDF::Reader.new(StringIO.new(pdf.compute_and_render))
      expect(pdf_test.page(1).text).to include(product_drive_donation.product_drive_participant.business_name)
      expect(pdf_test.page(1).text).to include(product_drive_donation.product_drive_participant.email)
      expect(pdf_test.page(1).text).to include(product_drive_donation.product_drive_participant.address)
      expect(pdf_test.page(1).text).to include(product_drive_donation.comment)
    end

    it "renders correctly without a product drive participant" do
      pdf = described_class.new(organization, product_drive_donation_without_participant)
      pdf_test = PDF::Reader.new(StringIO.new(pdf.compute_and_render))
      expect(pdf_test.page(1).text).to include(product_drive_donation_without_participant.product_drive.name)
      expect(pdf_test.page(1).text).to include(product_drive_donation_without_participant.comment)
    end
  end
end
