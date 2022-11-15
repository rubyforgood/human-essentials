class RequestItem
  attr_accessor :item, :quantity, :on_hand, :on_hand_for_location
  include ItemQuantity

  def self.from_json(json, request)
    location_id = request.partner.default_storage_location_id ||
      request.organization.default_storage_location
    location = StorageLocation.find_by(id: location_id)

    item = Item.find(json['item_id'])
    quantity = json['quantity']
    on_hand = request.organization.inventory_items.where(item_id: item.id).sum(:quantity)
    on_hand_for_location = if location
      location.inventory_items.where(item_id: item.id).sum(:quantity)
    else
      'N/A'
    end
    new(item, quantity, on_hand, on_hand_for_location)
  end

  delegate :name, to: :item

  def initialize(item, quantity, on_hand, on_hand_for_location)
    @item = item
    @quantity = quantity
    @on_hand = on_hand
    @on_hand_for_location = on_hand_for_location
  end
end
