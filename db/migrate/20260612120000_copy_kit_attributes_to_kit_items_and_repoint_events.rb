class CopyKitAttributesToKitItemsAndRepointEvents < ActiveRecord::Migration[8.0]
  # The Kit model is being removed; KitItem (an Item) becomes the standalone kit.
  # Move the kit's value_in_cents/visible_to_partners onto its kit item (the real values
  # previously lived on the kit), and repoint existing kit inventory events at the kit item
  # so inventory replay keeps working without the Kit class.
  #
  # Schema is intentionally left in place (kits table and items.kit_id remain) so this is
  # reversible at the data level; the columns just become vestigial.
  def up
    # Data-only updates against existing tables; safe to run.
    safety_assured do
      execute(<<-SQL.squish)
        UPDATE items
        SET value_in_cents = kits.value_in_cents,
            visible_to_partners = kits.visible_to_partners,
            updated_at = NOW()
        FROM kits
        WHERE items.kit_id = kits.id
      SQL

      execute(<<-SQL.squish)
        UPDATE events
        SET eventable_type = 'Item',
            eventable_id = items.id,
            updated_at = NOW()
        FROM items
        WHERE events.eventable_type = 'Kit'
          AND items.kit_id = events.eventable_id
      SQL
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
