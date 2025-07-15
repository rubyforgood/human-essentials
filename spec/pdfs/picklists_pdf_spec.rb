describe PicklistsPdf do
  let(:organization) { create(:organization) }
  let(:item1) { create(:item, name: "Item 1", organization: organization) }
  let(:item2) { create(:item, name: "Item 2", organization: organization) }

  describe "#compute_and_render" do
    it "renders multiple requests correctly" do
      request1 = create(:request, :pending, organization: organization, comments: "Request 1 comments")
      request2 = create(:request, :pending, organization: organization, comments: "Request 2 comments")
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
      expect(pdf_test.page(1).text).to include(request1.comments)
      expect(pdf_test.page(1).text).to include("Items Requested")
      expect(pdf_test.page(1).text).to include("Item 1")

      expect(pdf_test.page(2).text).to include(request2.partner.name)
      expect(pdf_test.page(2).text).to include(request2.partner.profile.primary_contact_name)
      expect(pdf_test.page(2).text).to include(request2.partner.profile.primary_contact_email)
      expect(pdf_test.page(2).text).to include("Requested on:")
      expect(pdf_test.page(2).text).to include("Items Received Year-to-Date:")
      expect(pdf_test.page(2).text).to include("Comments")
      expect(pdf_test.page(2).text).to include(request2.comments)
      expect(pdf_test.page(2).text).to include("Items Requested")
      expect(pdf_test.page(2).text).to include("Item 2")
    end

    context "when ytd_on_distribution_printout is enabled for the organization" do
      before { organization.update(ytd_on_distribution_printout: true) }

      it "renders the YTD quantity" do
        partner = create(:partner)
        request = create(:request, :pending, organization: organization, partner: partner)
        create(:item_request, request: request, item: item1, name: "Item 1", quantity: 17)

        # stub out the quantity_year_to_date method, it's not the PDF's job to make sure the calculation is correct
        allow(partner).to receive(:quantity_year_to_date).and_return(17827)
        pdf = described_class.new(organization, [request])
        pdf_test = PDF::Reader.new(StringIO.new(pdf.compute_and_render))

        expect(pdf_test.page(1).text).to include("Items Received Year-to-Date:")
        expect(pdf_test.page(1).text).to include("17827")
      end
    end

    context "When partner pickup person is set" do
      it "renders pickup person details" do
        partner = create(:partner)
        partner.profile.pick_up_name = "Paul Bunyan"
        partner.profile.pick_up_email = "paul@kenton.com"
        partner.profile.pick_up_phone = "503-123-4567"
        request = create(:request, :pending, organization: organization, partner: partner)
        pdf = described_class.new(organization, [request])
        pdf_test = PDF::Reader.new(StringIO.new(pdf.compute_and_render))

        expect(pdf_test.page(1).text).to include(request.partner.profile.pick_up_name)
        expect(pdf_test.page(1).text).to include(request.partner.profile.pick_up_email)
        expect(pdf_test.page(1).text).to include(request.partner.profile.pick_up_phone)
      end
    end

    context "when partner has a quota" do
      it "renders the quota information when quota is set" do
        partner = create(:partner)
        partner.update(quota: 100)
        request = create(:request, :pending, organization: organization, partner: partner)
        create(:item_request, request: request, item: item1, name: "Item 1")

        pdf = described_class.new(organization, [request])
        pdf_test = PDF::Reader.new(StringIO.new(pdf.compute_and_render))

        expect(pdf_test.page(1).text).to include("Quota:")
        expect(pdf_test.page(1).text).to include("100")
      end

      it "does not render quota information when quota is not set" do
        partner = create(:partner, quota: nil)
        request = create(:request, :pending, organization: organization, partner: partner)
        create(:item_request, request: request, item: item1, name: "Item 1")

        pdf = described_class.new(organization, [request])
        pdf_test = PDF::Reader.new(StringIO.new(pdf.compute_and_render))

        expect(pdf_test.page(1).text).not_to include("Quota:")
      end

      it "does not render quota information when quota is zero" do
        partner = create(:partner, quota: 0)
        request = create(:request, :pending, organization: organization, partner: partner)
        create(:item_request, request: request, item: item1, name: "Item 1")

        pdf = described_class.new(organization, [request])
        pdf_test = PDF::Reader.new(StringIO.new(pdf.compute_and_render))

        expect(pdf_test.page(1).text).not_to include("Quota:")
      end
    end
  end

  context "When packs are not enabled" do
    specify "#data_no_units" do
      request = create(:request, :pending, organization: organization)
      create(:item_request, request: request, item: item1, name: "Item 1", quantity: 5)
      create(:item_request, request: request, item: item2, name: "Item 2", quantity: 10)
      pdf = described_class.new(organization, [request])
      data = pdf.data_no_units(request.item_requests)

      expect(data).to eq([
        ["Items Requested", "Quantity", "[X]", "Differences / Comments"],
        ["Item 1", "5", "[  ]", ""],
        ["Item 2", "10", "[  ]", ""]
      ])
    end
  end

  context "When packs are enabled" do
    before { Flipper.enable(:enable_packs) }

    specify "#data_with_units" do
      item_with_units = create(:item, name: "Item with units", organization: organization)
      create(:item_unit, item: item_with_units, name: "Pack")
      request = create(:request, :pending, organization: organization)
      create(:item_request, request: request, item: item_with_units, name: "Item with units", request_unit: "Pack", quantity: 5)
      create(:item_request, request: request, item: item2, name: "Item 2", quantity: 10)
      pdf = described_class.new(organization, [request])
      data = pdf.data_with_units(request.item_requests)

      expect(data).to eq([
        ["Items Requested", "Quantity", "Unit (if applicable)", "[X]", "Differences / Comments"],
        ["Item with units", "5", "Packs", "[  ]", ""],
        ["Item 2", "10", nil, "[  ]", ""]
      ])
    end
  end
end
