class TransferCreateService
  class << self
    def call(transfer)
      if transfer.valid?
        ActiveRecord::Base.transaction do
          transfer.save
          transfer.from.decrease_inventory(transfer.line_item_hashes)
          transfer.to.increase_inventory(transfer.line_item_hashes)
          TransferEvent.publish(transfer)
        end
      else
        raise StandardError.new(transfer.errors.full_messages.join("</br>"))
      end
    end
  end
end
