class TransferCreateService
  class << self
    def call(transfer)
      if transfer.valid?
        ActiveRecord::Base.transaction do
          transfer.save
          transfer.from.decrease_inventory(transfer.line_item_values)
          transfer.to.increase_inventory(transfer.line_item_values)
          TransferEvent.publish(transfer)
        end
      else
        raise StandardError.new(transfer.errors.full_messages.join(", "))
      end
    end
  end
end
