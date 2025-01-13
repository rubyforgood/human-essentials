class RequestsTotalItemsService
  def initialize(requests:)
    @requests = requests
  end

  def calculate
    totals = Hash.new(0)
    item_requests.each do |item_request|
      totals[item_request.name_with_unit] += item_request.quantity.to_i
    end

    totals
  end

  private

  def item_requests
    @item_requests ||= Partners::ItemRequest.where(request: @requests)
  end
end
