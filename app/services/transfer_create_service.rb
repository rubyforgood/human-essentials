class TransferCreateService
  class << self
    def call(transfer)
      if transfer.valid?
        ActiveRecord::Base.transaction do
          transfer.save
          TransferEvent.publish(transfer)
        end
      else
        raise StandardError.new(transfer.errors.full_messages.join(", "))
      end
    end
  end
end
