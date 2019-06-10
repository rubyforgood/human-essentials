# Stakeholder requested the ability to value inventory
class AddValueToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :value, :decimal, precision: 5, scale: 2, default: 0
  end
end
