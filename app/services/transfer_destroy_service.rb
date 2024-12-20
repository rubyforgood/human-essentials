class TransferDestroyService
  def initialize(transfer_id:)
    @transfer_id = transfer_id
  end

  def call
    if Audit.finalized_since?(transfer, transfer.to_id, transfer.from_id)
      raise "We can't delete this transfer because its items were audited since you made the transfer."
    end

    transfer.transaction do
      TransferDestroyEvent.publish(transfer)
      transfer.destroy!
    end

    Result.new
  rescue StandardError => e
    Result.new(error: e)
  end

  private

  attr_reader :transfer_id

  def transfer
    @transfer ||= Transfer.find(transfer_id)
  end
end
