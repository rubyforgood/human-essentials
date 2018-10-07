class AddDistributionIdToRequests < ActiveRecord::Migration[5.2]
  def change
    add_column :requests, :distribution_id, :integer
  end
end
