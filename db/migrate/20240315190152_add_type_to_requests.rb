class AddTypeToRequests < ActiveRecord::Migration[7.0]
  def change
    add_column :requests, :type, :integer
  end
end
