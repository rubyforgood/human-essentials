class AddDiscardedToRequests < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      add_column :requests, :discarded_at, :datetime
      add_index :requests, :discarded_at
    end
  end
end
