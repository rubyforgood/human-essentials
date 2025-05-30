class RemoveShortNameFromOrganizations < ActiveRecord::Migration[8.0]
  def up
    safety_assured do
      remove_index :organizations, :short_name
      remove_column :organizations, :short_name
    end
  end

  def down
    add_column :organizations, :short_name
    add_index :organizations, :short_name
  end
end
