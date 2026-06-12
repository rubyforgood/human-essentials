module EventsHelper
  # KitItems (kit allocate/deallocate events) don't have their own route, so polymorphic
  # routing would look for a non-existent kit_item_path. Link them to the kits page instead.
  def eventable_path(eventable)
    eventable.is_a?(KitItem) ? kit_path(eventable) : eventable
  end
end
