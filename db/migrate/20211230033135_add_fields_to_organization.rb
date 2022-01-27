class AddFieldsToOrganization < ActiveRecord::Migration[6.1]
  def change
    add_column :organizations, :repackage_essentials, :boolean, null: false
    add_column :organizations, :distribute_monthly, :boolean, null: false
    change_column_default :organizations, :repackage_essentials, from: nil, to: false
    change_column_default :organizations, :distribute_monthly, from: nil, to: false
  end
end
