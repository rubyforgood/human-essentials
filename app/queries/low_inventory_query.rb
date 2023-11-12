class LowInventoryQuery
  def self.call(organization)
    scope = organization.inventory_items
    scope.where("inventory_items.quantity < items.on_hand_minimum_quantity")
      .or(scope.where("inventory_items.quantity < items.on_hand_recommended_quantity"))
      .includes(:item, :storage_location)
  end
end
