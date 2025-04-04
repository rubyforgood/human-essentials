class SetDefaultDistributionQuantity < ActiveRecord::Migration[7.2]
  def up
    Item.where(distribution_quantity: nil).find_each do |item|
      item.update_column(:distribution_quantity, item.kit_id.present? ? 1 : 50)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
