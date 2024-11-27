class PurchaseDestroyService
  class << self
    def call(purchase)
      ActiveRecord::Base.transaction do
        PurchaseDestroyEvent.publish(purchase)
        purchase.destroy!
      end
    end
  end
end
