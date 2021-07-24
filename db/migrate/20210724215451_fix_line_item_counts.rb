class FixLineItemCounts < ActiveRecord::Migration[6.1]
  def up
    LineItem.counter_culture_fix_counts
  end

  def down; end
end
