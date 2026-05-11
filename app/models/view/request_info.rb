module View
  RequestInfo = Data.define(
    :request
  ) do
    class << self
      def from_params(params:, organization:)
        request = organization.requests.find(params[:id])

        new(request:)
      end
    end

    def item_requests
      request.item_requests.includes(:item)
    end

    def inventory
      View::Inventory.new(request.organization_id)
    end

    def default_storage_location
      request.partner.default_storage_location_id || request.organization.default_storage_location
    end

    def location
      StorageLocation.find_by(id: default_storage_location)
    end

    def custom_units
      Flipper.enabled?(:enable_packs) && request.item_requests.any? { |item| item.request_unit }
    end
  end
end
