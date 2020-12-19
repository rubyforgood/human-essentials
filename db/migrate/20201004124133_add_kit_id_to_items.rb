class AddKitIdToItems < ActiveRecord::Migration[6.0]
  def up
    add_column :items, :kit_id, :integer

    add_index :items, :kit_id
    add_foreign_key :items, :kits
  end

  def down
    remove_column :items, :kit_id
  end
end
