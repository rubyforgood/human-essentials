class AddValueInCentsToKits < ActiveRecord::Migration[6.0]
  def change
    add_column :kits, :value_in_cents, :integer, default: 0
  end
end
