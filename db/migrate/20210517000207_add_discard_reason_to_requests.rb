class AddDiscardReasonToRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :requests, :discard_reason, :text
  end
end
