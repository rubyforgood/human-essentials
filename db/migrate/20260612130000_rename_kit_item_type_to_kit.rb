class RenameKitItemTypeToKit < ActiveRecord::Migration[8.0]
  # The KitItem STI class was renamed to Kit. Update the `type` discriminator on existing
  # item rows so they instantiate as the renamed class. Schema is unchanged.
  def up
    safety_assured do
      execute("UPDATE items SET type = 'Kit', updated_at = NOW() WHERE type = 'KitItem'")
    end
  end

  def down
    safety_assured do
      execute("UPDATE items SET type = 'KitItem', updated_at = NOW() WHERE type = 'Kit'")
    end
  end
end
