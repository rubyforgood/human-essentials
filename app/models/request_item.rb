class RequestItem
  attr_accessor :name, :quantity, :on_hand

  def self.from_json(json, organization)
    item = Item.find(json['item_id'])
    quantity = json['quantity']
    on_hand = organization.inventory_items.where(item_id: item.id).sum(:quantity)

    new(item.name, quantity, on_hand)
  end

  def initialize(name, quantity, on_hand)
    @name = name
    @quantity = quantity
    @on_hand = on_hand
  end
end
