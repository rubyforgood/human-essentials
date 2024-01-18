class PurchaseDestroyService
  class << self
    def call(purchase)
      ActiveRecord::Base.transaction do
        purchase.storage_location.decrease_inventory(purchase.line_item_values)
        PurchaseDestroyEvent.publish(purchase)
        purchase.destroy!
      end
    end
  end
end
