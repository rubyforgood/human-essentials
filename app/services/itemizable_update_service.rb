module ItemizableUpdateService
  # @param itemizable [Itemizable]
  # @param type [Symbol] :increase or :decrease - if the original line items added quantities (purchases or
  # donations), use :increase. If the original line_items reduced quantities (distributions) use :decrease.
  # @param params [Hash] Parameters passed from the controller. Should include `line_item_attributes`.
  def self.call(itemizable:, type: :increase, params: {})
    StorageLocation.transaction do
      item_ids = params[:line_items_attributes]&.values&.map { |i| i[:item_id].to_i } || []
      Item.reactivate(item_ids)

      from_location = to_location = itemizable.storage_location
      to_location = StorageLocation.find(params[:storage_location_id]) if params[:storage_location_id]

      apply_change_method = (type == :increase) ? :increase_inventory : :decrease_inventory
      undo_change_method = (type == :increase) ? :decrease_inventory : :increase_inventory

      line_item_attrs = Array.wrap(params[:line_items_attributes]&.values)
      line_item_attrs.each { |attr| attr.delete(:id) }

      update_storage_location(itemizable:          itemizable,
        apply_change_method: apply_change_method,
        undo_change_method:  undo_change_method,
        params:              params,
        from_location:       from_location,
        to_location:         to_location)
    end
  end

  # @param itemizable [Itemizable]
  # @param apply_change_method [Symbol]
  # @param undo_change_method [Symbol]
  # @param params [Hash] Parameters passed from the controller. Should include `line_item_attributes`.
  # @param from_location [StorageLocation]
  # @param to_location [StorageLocation]
  def self.update_storage_location(itemizable:, apply_change_method:, undo_change_method:,
    params:, from_location:, to_location:)
    from_location.public_send(undo_change_method, itemizable.to_a)
    # Delete the line items -- they'll be replaced later
    itemizable.line_items.delete_all
    # Update the current model with the new parameters
    itemizable.update!(params)
    itemizable.reload
    # Apply the new changes to the storage location inventory
    to_location.public_send(apply_change_method, itemizable.to_a)

    from_location.remove_empty_items
    to_location.remove_empty_items
  end
end
