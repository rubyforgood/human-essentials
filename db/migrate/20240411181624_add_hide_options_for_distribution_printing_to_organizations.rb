class AddHideOptionsForDistributionPrintingToOrganizations < ActiveRecord::Migration[7.0]
  def change
    add_column :organizations, :hide_value_columns_on_receipt, :boolean
    add_column :organizations, :hide_package_column_on_receipt, :boolean
    # Followed strong migration advice, with Backfill migration too
    change_column_default :organizations, :hide_value_columns_on_receipt, false
    change_column_default :organizations, :hide_package_column_on_receipt, false
  end
end
