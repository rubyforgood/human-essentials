class AddActiveToKits < ActiveRecord::Migration[6.0]
  def change
    add_column :kits, :active, :boolean, default: true
  end
end
