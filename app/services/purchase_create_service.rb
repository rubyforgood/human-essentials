class PurchaseCreateService
  class << self
    def call(purchase)
      Purchase.transaction do
        unless purchase.save
          raise purchase.errors.full_messages.join("\n")
        end
        purchase.storage_location.increase_inventory(purchase.line_item_values)
        PurchaseEvent.publish(purchase)
      end
    end
  end
end
