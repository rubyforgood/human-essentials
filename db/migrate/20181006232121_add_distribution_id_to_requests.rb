# Connect Distributions with the Requests from whence they came
class AddDistributionIdToRequests < ActiveRecord::Migration[5.2]
  def change
    add_column :requests, :distribution_id, :integer
  end
end
