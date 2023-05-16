class AddIndicesToCounties < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    add_index :counties, :name, algorithm: :concurrently
    add_index :counties, :region, algorithm: :concurrently
    add_index :counties, [:name, :region], unique: true, algorithm: :concurrently

  end
end
