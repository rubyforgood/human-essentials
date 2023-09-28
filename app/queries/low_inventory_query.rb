class LowInventoryQuery
  attr_reader :organization

  def initialize(organization:)
    @organization = organization
  end

  def call
    scope = organization.inventory_items
    scope.where("inventory_items.quantity < items.on_hand_minimum_quantity")
      .or(scope.where("inventory_items.quantity < items.on_hand_recommended_quantity"))
      .includes(:item, :storage_location)
  end
end
