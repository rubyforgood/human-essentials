class AddNoneNegativeConstraintOnDistributionQuantity < ActiveRecord::Migration[6.0]
  def up
    safety_assured {
      execute <<-SQL
        ALTER TABLE items
        ADD CONSTRAINT distribution_quantity_nonnegative 
        CHECK (distribution_quantity >= 0);
      SQL
    }
  end

  def down
    safety_assured {
      execute <<-SQL
        ALTER TABLE items
        DROP CONSTRAINT distribution_quantity_nonnegative 
      SQL
    }
  end
end
