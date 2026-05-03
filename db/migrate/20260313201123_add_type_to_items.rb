class AddTypeToItems < ActiveRecord::Migration[8.0]
  def up
    add_column :items, :type, :string, default: 'ConcreteItem', null: false
    Item.where.not(kit_id: nil).update_all(type: 'KitItem', updated_at: Time.zone.now)
  end

  def down
    remove_column :items, :type
  end

end
