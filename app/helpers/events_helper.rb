module EventsHelper
  # KitAllocateEvent/KitDeallocateEvent mix directions within a single event: the
  # kit's own line item moves opposite the component items, so we can't rely on
  # picking any one item's from/to. Every item shares the same storage location
  # (just recorded in the opposite field for the kit vs. its components), so pull
  # that location from whichever entry has it and place it by event type instead.
  def event_direction_locations(event)
    if event.is_a?(KitAllocateEvent) || event.is_a?(KitDeallocateEvent)
      first_item = event.data.items.first
      kit_storage_loc = first_item&.from_storage_location || first_item&.to_storage_location
      from_loc = event.is_a?(KitDeallocateEvent) ? kit_storage_loc : nil
      to_loc = event.is_a?(KitAllocateEvent) ? kit_storage_loc : nil
    else
      from_loc = event.data.items.first&.from_storage_location
      to_loc = event.data.items.first&.to_storage_location
    end
    [from_loc, to_loc]
  end
end
