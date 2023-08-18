class LevelUpInvetoryIn < ActiveRecord::Migration[7.0]
  def change
    Rake::Task["kit_allocation:inventory_in"].invoke
  end
end
