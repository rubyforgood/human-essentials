class ConvertNegativeDistributionQuantityIntoPositive < ActiveRecord::Migration[6.0]
  def change
    safety_assured {
      execute <<-SQL
        UPDATE items 
        SET distribution_quantity = ABS(distribution_quantity) 
        WHERE distribution_quantity < 0
      SQL
    }
  end
end
