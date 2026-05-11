RSpec.describe View::RequestInfo do
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

        request = View::RequestInfo.from_params(params: {id: request.id}, organization:)

        expect(request.default_storage_location).to eq(storage_location.id)
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

        request = View::RequestInfo.from_params(params: {id: request.id}, organization:)

        expect(request.default_storage_location).to eq(storage_location.id)
      end
    end
  end

  describe "#custom_units" do
    context "when a request has request units for an item request" do
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
              {item_id: item.id, quantity: '559', request_unit: 'flat'}
            ]
          )

          request = View::RequestInfo.from_params(params: {id: request.id}, organization:)

          expect(request.custom_units).to be_falsey
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
              {item_id: item.id, quantity: '559', request_unit: 'flat'},
            ]
          )
          request = View::RequestInfo.from_params(params: {id: request.id}, organization:)

          expect(request.custom_units).to be_truthy

          Flipper.disable(:enable_packs)
        end
      end
    end
  end
end
