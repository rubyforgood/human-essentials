class UpdateDistributionQtyFromZeroToNull < ActiveRecord::Migration[7.0]
  def up
    Item.where(distribution_quantity: 0).update_all(distribution_quantity: nil)
  end

  def down
  end
end
