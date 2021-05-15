class AddDiscardedToRequests < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      add_column :partner_requests, :discarded_at, :datetime
      add_index :partner_requests, :discarded_at
    end
  end
end
