class RequestItem
  attr_accessor :name, :quantity, :on_hand, :on_hand_for_location

  def self.from_json(json, organization, location)
    item = Item.find(json['item_id'])
    quantity = json['quantity']
    on_hand = organization.inventory_items.where(item_id: item.id).sum(:quantity)
    on_hand_for_location = if location
      location.inventory_items.where(item_id: item.id).sum(:quantity)
    else
      'N/A'
    end
    new(item.name, quantity, on_hand, on_hand_for_location)
  end

  def initialize(name, quantity, on_hand, on_hand_for_location)
    @name = name
    @quantity = quantity
    @on_hand = on_hand
    @on_hand_for_location = on_hand_for_location
  end
end
