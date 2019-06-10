class ChangeItemValueToInteger < ActiveRecord::Migration[5.2]
  def self.up
    change_column :items, :value, :integer, default: 0
  end

  def self.down
    change_column :items, :value, :decimal, precision: 5, scale: 2, default: 0
  end
end
