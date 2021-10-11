class AddFkOnDistributionIdOfRequests < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      add_foreign_key :requests, :distributions
      add_index :requests, :distribution_id, unique: true
    end
  end
end
