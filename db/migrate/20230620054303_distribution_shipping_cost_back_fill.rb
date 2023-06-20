class DistributionShippingCostBackFill < ActiveRecord::Migration[7.0]
  def change
    Distribution.update_all(shipping_cost: 0)
  end
end
