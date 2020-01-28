class TransferUpdateService

  def initialize(transfer_id:, update_params:)
    @transfer_id = transfer_id
    @update_params = update_params
  end

  def call
    transfer.transaction do
      # Get a copy of the original transfer before any changes
      old_transfer = transfer.dup
      updated_transfer = transfer.tap do |t|
        t.assign_attributes(update_params)
      end

      if update_inventory_count?(old_transfer, updated_transfer)
        reconcile_inventory_count!(old_transfer, updated_transfer)
      end

      updated_transfer.save!

      OpenStruct.new(success?: true)
    end
  rescue StandardError => e
    OpenStruct.new(success?: false, error: e)
  end

  private

  attr_reader :transfer_id, :update_params

  def transfer
    @transfer ||= Transfer.find(transfer_id)
  end

  def update_inventory_count?(transfer, updated_transfer)
    # Returns true if the update should trigger
    # a update inventory count operations.
    transfer.from_id != updated_transfer.from_id ||
      transfer.to_id != updated_transfer.to_id ||
      transfer.to_a != updated_transfer.to_a
  end

  def revert_inventory_transfer!
    transfer.to.decrease_inventory(transfer)
    transfer.from.increase_inventory(transfer)
  end

  def reconcile_inventory_count!(old_transfer, updated_transfer)
    # Remove all old changes made
    old_transfer.from.increase_inventory(old_transfer)
    old_transfer.to.decrease_inventory(old_transfer)

    # Apply new inventory changes
    updated_transfer.to.decrease_inventory(updated_transfer)
    updated_transfer.from.increase_inventory(updated_transfer)
  end

end
