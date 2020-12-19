class AddIndexOnKits < ActiveRecord::Migration[6.0]
  def change
    add_index :kits, [:name, :organization_id], unique: true
    change_column_null :kits, :organization_id, false
    change_column_null :kits, :name, false
  end
end
