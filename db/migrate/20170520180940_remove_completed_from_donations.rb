class RemoveCompletedFromDonations < ActiveRecord::Migration[5.0]
  def change
    remove_column :donations, :completed
  end
end
