class PurchaseCreateService
  class << self
    def call(purchase)
      Purchase.transaction do
        unless purchase.save
          raise purchase.errors.full_messages.join("\n")
        end
        PurchaseEvent.publish(purchase)
      end
    end
  end
end
