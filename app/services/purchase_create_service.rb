class PurchaseCreateService
  class << self
    def call(purchase)
      if purchase.save
        purchase.storage_location.increase_inventory(purchase.line_item_values)
        PurchaseEvent.publish(purchase)
      end
    end
  end
end
