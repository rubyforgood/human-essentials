class RemoveIndexOnNameFromCountiesTable < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    remove_index :counties, :name, algorithm: :concurrently
  end
end
