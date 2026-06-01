module View
  class RequestInfo
    attr_reader :request

    def initialize(params:, organization:)
      @request = organization.requests.find(params[:id])
    end

    def item_requests
      @item_requests ||= @request.item_requests.includes(:item)
    end

    def inventory
      @inventory ||= View::Inventory.new(@request.organization_id)
    end

    def default_storage_location
      return @default_storage_location if defined?(@default_storage_location)

      @efault_storage_location ||= @request.partner.default_storage_location_id || @request.organization.default_storage_location
    end

    def location
      return @location if defined?(@location)

      @location ||= StorageLocation.find_by(id: default_storage_location)
    end

    def custom_units
      Flipper.enabled?(:enable_packs) && request.item_requests.any? { |item| item.request_unit }
    end
  end
end
