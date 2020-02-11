class ChangeItemsValuesFieldName < ActiveRecord::Migration[5.2]
  def self.up
    rename_column :items, :value, :value_in_cents
  end

  def self.down
    rename_column :items, :value_in_cents, :value
  end
end
