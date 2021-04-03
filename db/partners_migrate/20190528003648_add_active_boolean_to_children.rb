class AddActiveBooleanToChildren < ActiveRecord::Migration[5.2]
  def change
    add_column :children, :active, :boolean, default: true
  end
end
