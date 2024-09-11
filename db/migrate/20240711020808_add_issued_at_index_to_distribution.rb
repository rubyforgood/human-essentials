class AddIssuedAtIndexToDistribution < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :distributions, :issued_at, algorithm: :concurrently
  end
end
