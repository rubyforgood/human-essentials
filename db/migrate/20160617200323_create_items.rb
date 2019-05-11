# Creates the initial "Items" table
class CreateItems < ActiveRecord::Migration[5.0]
  def change
    create_table :items do |t|
      t.string :name
      t.string :category

      t.timestamps
    end
  end
end
