class RequestsTotalItemsService
  def initialize(requests:)
    @requests = requests
  end

  def calculate
    return unless requests

    request_items_array = []
    items_names = Item.where(id: request_items_ids).as_json(only: [:id, :name])

    request_items.each do |items|
      items.each do |json|
        request_items_array << [item_name(items_names, json['item_id']), json['quantity']]
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

  def request_items_ids
    request_items.flat_map { |jitem| jitem.map { |item| item["item_id"] } }
  end

  def request_items
    @request_items ||= requests.pluck(:request_items)
  end

  def item_name(items_names, id)
    item_found = items_names.select { |item| item["id"] == id }
    item_found.first["name"].presence || ""
  end
end
