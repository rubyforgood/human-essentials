class AddDiscardedAtToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :discarded_at, :datetime
  end
end
