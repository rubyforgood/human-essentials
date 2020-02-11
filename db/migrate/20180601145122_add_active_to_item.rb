# We wanted the ability to delete items without actually deleting them
class AddActiveToItem < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :active, :boolean, default: true
  end
end
