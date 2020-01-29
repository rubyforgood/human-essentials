class TransferUpdateService

  def initialize(transfer_id:, update_params:)
    @transfer_id = transfer_id
    @update_params = update_params
  end

  def call
    transfer.transaction do
      # Get a copy of the original transfer before any changes
      #
      # The old line items are getting removed at this point.
      # Make sure to keep it stored.
      old_transfer = transfer.clone
      old_line_items = transfer.to_a.dup
      updated_transfer = transfer.tap do |t|
        t.assign_attributes(update_params)
      end
      updated_line_items = updated_transfer.to_a

      if changed_storage_location?(old_transfer, updated_transfer) || old_line_items != updated_line_items
        reconcile_inventory_count!(
          old_transfer,
          old_line_items,
          updated_transfer,
          updated_line_items
        )
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

  def changed_storage_location?(transfer, updated_transfer)
    # Returns true if the update should trigger
    # a update inventory count operations.
    transfer.from_id != updated_transfer.from_id || transfer.to_id != updated_transfer.to_id
  end

  def reconcile_inventory_count!(old_transfer, old_line_items, updated_transfer, updated_line_items)
    # TODO - handling the removal case
    #
    # Remove all old changes made
    old_transfer.to.decrease_inventory(old_line_items)
    old_transfer.from.increase_inventory(old_line_items)

    # Apply new inventory changes
    updated_transfer.from.decrease_inventory(updated_line_items)
    updated_transfer.to.increase_inventory(updated_line_items)
  end

end
