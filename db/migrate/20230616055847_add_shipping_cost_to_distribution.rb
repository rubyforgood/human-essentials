class AddShippingCostToDistribution < ActiveRecord::Migration[7.0]
  def up
    add_column :distributions, :shipping_cost, :decimal, precision: 8, scale: 2
  end

  def down
    remove_column :distributions, :shipping_cost
  end
end
