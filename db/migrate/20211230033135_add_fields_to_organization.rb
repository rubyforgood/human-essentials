class AddFieldsToOrganization < ActiveRecord::Migration[6.1]
  def change
    add_column :organizations, :repackage_essentials, :boolean, default: false, null: false
    add_column :organizations, :distribute_monthly, :boolean, default: false, null: false
  end
end
