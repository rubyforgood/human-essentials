RSpec.describe View::RequestInfo do
  describe "#item_requests" do
    context "when the request has item requests" do
      it "returns the request's item requests" do
        organization = build(:organization)
        item = build(:item)
        item_request = build(:item_request, item: item, quantity: 5)
        request = create(
          :request,
          organization:,
          item_requests: [item_request]
        )

        request_info = View::RequestInfo.from_params(params: {id: request.id}, organization:)

        expect(request_info.item_requests).to eq([item_request])
      end
    end

    context "when the request has no item requests" do
      it "returns an empty array" do
        organization = build(:organization)
        request = create(:request, organization:)

        request_info = View::RequestInfo.from_params(params: {id: request.id}, organization:)

        expect(request_info.item_requests).to eq([])
      end
    end
  end

  describe "#inventory" do
    it "returns a View::Inventory instance" do
      organization = build(:organization)
      request = create(:request, organization:)

      request_info = View::RequestInfo.from_params(params: {id: request.id}, organization:)

      expect(request_info.inventory).to be_a_kind_of(View::Inventory)
    end
  end

  describe "#default_storage_location" do
    context "when the request partner has a default_storage_location_id" do
      it "returns the request partner's default_storage_location_id" do
        storage_location = build(:storage_location)
        organization = build(:organization)
        request = create(
          :request,
          partner: build(:partner, default_storage_location_id: storage_location.id),
          organization:
        )

        request_info = View::RequestInfo.from_params(params: {id: request.id}, organization:)

        expect(request_info.default_storage_location).to eq(storage_location.id)
      end
    end

    context "when the request organization has a default_storage_location_id" do
      it "returns the request organization's default_storage_location_id" do
        organization = build(:organization)
        storage_location = build(:storage_location, organization:)
        organization.update!(default_storage_location: storage_location.id)
        request = create(
          :request,
          organization:
        )

        request_info = View::RequestInfo.from_params(params: {id: request.id}, organization:)

        expect(request_info.default_storage_location).to eq(storage_location.id)
      end
    end
  end

  describe "#location" do
    context "when no storage location is found" do
      it "returns nil" do
        organization = build(:organization)
        request = create(:request, organization:)

        request_info = View::RequestInfo.from_params(params: {id: request.id}, organization:)

        expect(request_info.location).to be_nil
      end
    end

    context "when a storage location is found" do
      it "returns the found location" do
        organization = build(:organization)
        storage_location = create(:storage_location, organization:)
        organization.update!(default_storage_location: storage_location.id)
        request = create(
          :request,
          organization:
        )

        request_info = View::RequestInfo.from_params(params: {id: request.id}, organization:)

        expect(request_info.location).to be_a_kind_of(StorageLocation)
      end
    end
  end

  describe "#custom_units" do
    context "when there are request units for an item request" do
      context "when enable_packs is disabled" do
        it "returns false" do
          organization = build(:organization)
          item = build(:item, name: "First item")
          create(:item_unit, item: item, name: "flat")
          request = create(
            :request,
            :with_item_requests,
            organization:,
            request_items: [
              {item_id: item.id, quantity: "559", request_unit: "flat"}
            ]
          )

          request_info = View::RequestInfo.from_params(params: {id: request.id}, organization:)

          expect(request_info.custom_units).to be_falsey
        end
      end

      context "when enable_packs is enabled" do
        it "returns true" do
          Flipper.enable(:enable_packs)

          organization = build(:organization)
          item = build(:item, name: "First item")
          create(:item_unit, item: item, name: "flat")
          request = create(
            :request,
            :with_item_requests,
            organization:,
            request_items: [
              {item_id: item.id, quantity: "559", request_unit: "flat"}
            ]
          )
          request_info = View::RequestInfo.from_params(params: {id: request.id}, organization:)

          expect(request_info.custom_units).to be_truthy

          Flipper.disable(:enable_packs)
        end
      end
    end
  end
end
