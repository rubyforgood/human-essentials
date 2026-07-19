class RemoveItemCategory < ActiveRecord::Migration[8.0]
  def up
    safety_assured do
      remove_column :items, :category
    end
  end

  def down
    add_column :items, :category, :string
  end
end
