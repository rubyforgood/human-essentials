module ItemizableUpdateService
  # @param itemizable [Itemizable]
  # @param type [Symbol] :increase or :decrease - if the original line items added quantities (purchases or
  # donations), use :increase. If the original line_items reduced quantities (distributions) use :decrease.
  # @param params [Hash] Parameters passed from the controller. Should include `line_item_attributes`.
  # @param event_class [Class<Event>] the event class to publish the itemizable to.
  def self.call(itemizable:, type: :increase, params: {}, event_class: nil)
    StorageLocation.transaction do
      item_ids = params[:line_items_attributes]&.values&.map { |i| i[:item_id].to_i } || []
      inactive_item_names = Item.where(id: item_ids, active: false).pluck(:name)
      if inactive_item_names.any?
        raise "Update failed: The following items are currently inactive: #{inactive_item_names.join(", ")}. Please reactivate them before continuing."
      end

      from_location = to_location = itemizable.storage_location
      to_location = StorageLocation.find(params[:storage_location_id]) if params[:storage_location_id]

      verify_intervening_audit_on_storage_location_items(itemizable: itemizable, from_location_id: from_location.id, to_location_id: to_location.id)

      apply_change_method = (type == :increase) ? :increase_inventory : :decrease_inventory
      undo_change_method = (type == :increase) ? :decrease_inventory : :increase_inventory

      previous = nil
      # TODO once event sourcing has been out for long enough, we can safely remove this
      if Event.where(eventable: itemizable).none? || UpdateExistingEvent.where(eventable: itemizable).any?
        previous = itemizable.line_items.map(&:dup)
      end

      line_item_attrs = Array.wrap(params[:line_items_attributes]&.values)
      line_item_attrs.each { |attr| attr.delete(:id) }

      update_storage_location(itemizable:          itemizable,
        apply_change_method: apply_change_method,
        undo_change_method:  undo_change_method,
        params:              params,
        from_location:       from_location,
        to_location:         to_location)
      if previous
        UpdateExistingEvent.publish(itemizable, previous)
      else
        event_class&.publish(itemizable)
      end
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
    from_location.public_send(undo_change_method, itemizable.line_item_values)
    # Delete the line items -- they'll be replaced later
    itemizable.line_items.delete_all
    # Update the current model with the new parameters
    itemizable.update!(params)
    itemizable.reload
    # Apply the new changes to the storage location inventory
    to_location.public_send(apply_change_method, itemizable.line_item_values)
  end

  # @param itemizable [Itemizable]
  # @param from_location [StorageLocation]
  # @param to_location [StorageLocation]
  def self.verify_intervening_audit_on_storage_location_items(itemizable:, from_location_id:, to_location_id:)
    return if from_location_id == to_location_id || !Audit.finalized_since?(itemizable, [from_location_id, to_location_id])

    itemizable_type = itemizable.class.name.downcase
    case itemizable_type
    when "distribution"
      raise "Cannot change the storage location because there has been an intervening audit of some items. " \
      "If you need to change the storage location, please reclaim this distribution and create a new distribution from the new storage location."
    else
      raise "Cannot change the storage location because there has been an intervening audit of some items. " \
      "If you need to change the storage location, please delete this #{itemizable_type} and create a new #{itemizable_type} with the new storage location."
    end
  end
end
