class PurchaseCreateService
  class << self
    def call(purchase)
      Purchase.transaction do
        if purchase.save
          purchase.storage_location.increase_inventory(purchase)
          PurchaseEvent.publish(purchase)
        end
      end
    end
  end
end
