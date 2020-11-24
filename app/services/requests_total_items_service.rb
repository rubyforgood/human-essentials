class RequestsTotalItemsService
  def initialize(requests:)
    @requests = requests
  end

  def calculate
    return unless requests

    request_items_array = []

    request_items.each do |items|
      items.each do |json|
        request_items_array << [item_name(json['item_id']), json['quantity']]
      end
    end

    request_items_array.inject({}) do |item, (quantity, total)|
      item[quantity] ||= 0
      item[quantity] += total.to_i
      item
    end
  end

  private

  attr_accessor :requests

  def request_items
    @request_items ||= requests.pluck(:request_items)
  end

  def request_items_ids
    request_items.flat_map { |jitem| jitem.map { |item| item["item_id"] } }
  end

  def items_names
    @items_names ||= Item.where(id: request_items_ids).as_json(only: [:id, :name])
  end

  def item_name(id)
    item_found = items_names.find { |item| item["id"] == id }
    item_found&.fetch('name') || '*Unknown Item*'
  end
end
