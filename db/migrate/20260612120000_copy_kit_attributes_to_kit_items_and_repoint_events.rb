class CopyKitAttributesToKitItemsAndRepointEvents < ActiveRecord::Migration[8.0]
  # The Kit model is being removed; KitItem (an Item) becomes the standalone kit.
  # Repoint existing kit inventory events at the kit item so inventory replay keeps
  # working without the Kit class.
  #
  # Schema is intentionally left in place (kits table and items.kit_id remain) so this is
  # reversible at the data level; the columns just become vestigial.
  def up
    # Data-only updates against existing tables; safe to run.
    safety_assured do
      execute(<<-SQL.squish)
        UPDATE events
        SET eventable_type = 'Item',
            eventable_id = items.id,
            updated_at = NOW()
        FROM items
        WHERE events.eventable_type = 'Kit'
          AND items.kit_id = events.eventable_id
      SQL

      # Every kit event must now point at an item; a leftover means a kit with no item
      # row, which would break event replay and event history once the Kit class is gone.
      leftover = select_value("SELECT COUNT(*) FROM events WHERE eventable_type = 'Kit'")
      if leftover.to_i.positive?
        raise "#{leftover} events still reference Kit eventables with no matching item; " \
              "fix those kits before migrating"
      end
    end
  end

  def down
    # Kit allocate/deallocate events were the only events with Kit eventables.
    safety_assured do
      execute(<<-SQL.squish)
        UPDATE events
        SET eventable_type = 'Kit',
            eventable_id = items.kit_id,
            updated_at = NOW()
        FROM items
        WHERE events.eventable_type = 'Item'
          AND events.eventable_id = items.id
          AND events.type IN ('KitAllocateEvent', 'KitDeallocateEvent')
          AND items.kit_id IS NOT NULL
      SQL
    end
  end
end
