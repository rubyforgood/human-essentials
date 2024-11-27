class AddPackModels < ActiveRecord::Migration[7.0]
  def change
    create_table :units do |t|
      t.string :name, null: false
      t.references :organization, foreign_key: true
      t.timestamps
    end

    create_table :item_units do |t|
      t.string :name, null: false
      t.references :item, foreign_key: true
      t.timestamps
    end

  end
end
