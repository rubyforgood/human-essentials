class AddPriceToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :price, :decimal, precision: 5, scale: 2, default: 0
  end
end
