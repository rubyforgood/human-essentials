# Initial table for Transfers
class CreateTransfers < ActiveRecord::Migration[5.0]
  def change
    create_table :transfers do |t|
      t.integer :from_id
      t.integer :to_id
      t.string :comment

      t.timestamps null: false
    end
  end
end
