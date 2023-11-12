class PurchaseDestroyService
  class << self
    def call(purchase)
      ActiveRecord::Base.transaction do
        purchase.storage_location.decrease_inventory(purchase)
        PurchaseDestroyEvent.publish(purchase)
        purchase.destroy!
      end
    end
  end
end
