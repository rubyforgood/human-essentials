describe PicklistsPdf do
  let(:organization) { create(:organization) }
  let(:item1) { create(:item, name: "Item 1", organization: organization) }
  let(:item2) { create(:item, name: "Item 2", organization: organization) }

  describe "#compute_and_render" do
    it "renders multiple requests correctly" do
      request1 = create(:request, :pending, organization: organization)
      request2 = create(:request, :pending, organization: organization)
      create(:item_request, request: request1, item: item1, name: "Item 1")
      create(:item_request, request: request2, item: item2, name: "Item 2")

      pdf = described_class.new(organization, [request1, request2])
      pdf_test = PDF::Reader.new(StringIO.new(pdf.compute_and_render))

      expect(pdf_test.page(1).text).to include(request1.partner.name)
      expect(pdf_test.page(1).text).to include(request1.partner.profile.primary_contact_name)
      expect(pdf_test.page(1).text).to include(request1.partner.profile.primary_contact_email)
      expect(pdf_test.page(1).text).to include("Requested on:")
      expect(pdf_test.page(1).text).to include("Items Received Year-to-Date:")
      expect(pdf_test.page(1).text).to include("Comments")
      expect(pdf_test.page(1).text).to include("Items Requested")
      expect(pdf_test.page(1).text).to include("Item 1")

      expect(pdf_test.page(2).text).to include(request2.partner.name)
      expect(pdf_test.page(2).text).to include(request2.partner.profile.primary_contact_name)
      expect(pdf_test.page(2).text).to include(request2.partner.profile.primary_contact_email)
      expect(pdf_test.page(2).text).to include("Requested on:")
      expect(pdf_test.page(2).text).to include("Items Received Year-to-Date:")
      expect(pdf_test.page(2).text).to include("Comments")
      expect(pdf_test.page(2).text).to include("Items Requested")
      expect(pdf_test.page(2).text).to include("Item 2")
    end

    context "When partner pickup person is set" do
      it "renders pickup person details" do
        partner = create(:partner, pick_up_person: true)
        request = create(:request, :pending, organization: organization, partner: partner)
        pdf = described_class.new(organization, [request])
        pdf_test = PDF::Reader.new(StringIO.new(pdf.compute_and_render))

        expect(pdf_test.page(1).text).to include(request.partner.profile.pick_up_name)
        expect(pdf_test.page(1).text).to include(request.partner.profile.pick_up_email)
        expect(pdf_test.page(1).text).to include(request.partner.profile.pick_up_phone)
      end
    end
  end

  context "When packs are not enabled" do
    specify "#data_no_units" do
      request = create(:request, :pending, organization: organization)
      create(:item_request, request: request, item: item1, name: "Item 1")
      create(:item_request, request: request, item: item2, name: "Item 2")
      pdf = described_class.new(organization, [request])
      data = pdf.data_no_units(request.item_requests)

      expect(data).to eq([
        ["Items Requested", "Quantity", "[X]", "Differences / Comments"],
        ["Item 1", "5", "[  ]", ""],
        ["Item 2", "5", "[  ]", ""]
      ])
    end
  end

  context "When packs are enabled" do
    before { Flipper.enable(:enable_packs) }

    specify "#data_with_units" do
      item_with_units = create(:item, name: "Item with units", organization: organization)
      create(:item_unit, item: item_with_units, name: "Pack")
      request = create(:request, :pending, organization: organization)
      create(:item_request, request: request, item: item_with_units, name: "Item with units", request_unit: "Pack")
      create(:item_request, request: request, item: item2, name: "Item 2")
      pdf = described_class.new(organization, [request])
      data = pdf.data_with_units(request.item_requests)

      expect(data).to eq([
        ["Items Requested", "Quantity", "Unit (if applicable)", "[X]", "Differences / Comments"],
        ["Item with units", "5", "Packs", "[  ]", ""],
        ["Item 2", "5", nil, "[  ]", ""]
      ])
    end
  end
end
