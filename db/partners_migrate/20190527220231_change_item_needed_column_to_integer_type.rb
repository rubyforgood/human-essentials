class ChangeItemNeededColumnToIntegerType < ActiveRecord::Migration[5.2]
  def change
    remove_column :children, :item_needed, :integer
    add_column :children, :item_needed_diaperid, :integer
  end
end
