# Creates the initial "Inventories" table (these are later renamed)
class CreateInventories < ActiveRecord::Migration[5.0]
  def change
    create_table :inventories do |t|
      t.string :name
    	t.string :address

      t.timestamps
    end

    add_reference :donations, :inventory, index: true, foreign_key: true
  end
end
