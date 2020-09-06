class AddDiscardedAtIndexToUsers < ActiveRecord::Migration[6.0]
  def change
    add_index :users, :discarded_at
  end
end
