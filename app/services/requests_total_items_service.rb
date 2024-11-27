class RequestsTotalItemsService
  def initialize(requests:)
    @requests = requests.includes(item_requests: {item: :request_units})
  end

  def calculate
    return unless requests

    totals = Hash.new(0)
    item_requests.each do |item_request|
      totals[item_request.name_with_unit] += item_request.quantity.to_i
    end

    totals
  end

  private

  attr_accessor :requests

  def item_requests
    @item_requests ||= requests.flat_map(&:item_requests)
  end
end
