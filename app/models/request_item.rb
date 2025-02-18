class RequestItem
  attr_accessor :item, :quantity, :unit, :on_hand, :on_hand_for_location
  include ItemQuantity

  def self.from_json(json, request, inventory = nil)
    location_id = request.partner.default_storage_location_id ||
      request.organization.default_storage_location
    location = StorageLocation.find_by(id: location_id)

    item = Item.find(json['item_id'])
    quantity = json['quantity']
    unit = request.item_requests.find { |item_request| item_request.item_id == item.id }&.request_unit
    if inventory
      on_hand = inventory.quantity_for(item_id: item.id)
      on_hand_for_location = inventory.quantity_for(storage_location: location&.id, item_id: item.id)
    end
    new(item, quantity, unit, on_hand, on_hand_for_location&.positive? ? on_hand_for_location : 'N/A')
  end

  delegate :name, to: :item

  def initialize(item, quantity, unit, on_hand, on_hand_for_location)
    @item = item
    @quantity = quantity
    @unit = unit
    @on_hand = on_hand
    @on_hand_for_location = on_hand_for_location
  end
end
