class TransferDestroyService
  def initialize(transfer_id:)
    @transfer_id = transfer_id
  end

  def call
    transfer.transaction do
      revert_inventory_transfer!
      TransferDestroyEvent.publish(transfer)
      transfer.destroy!
    end

    OpenStruct.new(success?: true)
  rescue StandardError => e
    OpenStruct.new(success?: false, error: e)
  end

  private

  attr_reader :transfer_id

  def transfer
    @transfer ||= Transfer.find(transfer_id)
  end

  def revert_inventory_transfer!
    transfer.to.decrease_inventory(transfer.line_item_values)
    transfer.from.increase_inventory(transfer.line_item_values)
  end
end
