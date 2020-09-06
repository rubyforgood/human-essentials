class AddDeliveryMethodToDistribution < ActiveRecord::Migration[6.0]
  def change
    add_column :distributions, :delivery_method, :integer
  end
end
