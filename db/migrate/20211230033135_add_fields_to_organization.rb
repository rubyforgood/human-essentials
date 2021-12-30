class AddFieldsToOrganization < ActiveRecord::Migration[6.1]
  def change
    add_column :organizations, :repackage_essentials, :boolean, null: false, default: false
    add_column :organizations, :distribute_monthly, :boolean, null: false, default: false
  end
end
