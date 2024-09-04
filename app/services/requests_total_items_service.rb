class RequestsTotalItemsService
  def initialize(requests:)
    @requests = requests
  end

  def calculate
    return unless requests

    totals = {}
    item_requests.each do |item_request|
      name = item_name(item_request)
      totals[name] ||= 0
      totals[name] += item_request.quantity.to_i
    end

    totals
  end

  private

  attr_accessor :requests

  def item_requests
    @item_requests ||= requests.flat_map(&:item_requests)
  end

  def item_name(item_request)
    if Flipper.enabled?(:enable_packs) && item_request.request_unit
      "#{item_request.name} - #{item_request.request_unit}"
    else
      item_request.name
    end
  end
end
