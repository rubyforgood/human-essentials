# Creates the initial Adjustments table
class CreateAdjustments < ActiveRecord::Migration[5.0]
  def change
    create_table :adjustments do |t|
      t.references :organization, foreign_key: true
      t.references :storage_location, foreign_key: true
      t.text :comment

      t.timestamps
    end
  end
end
