class DropNeededItems < ActiveRecord::Migration[7.0]
  def change
    drop_table :needed_items
  end
end
