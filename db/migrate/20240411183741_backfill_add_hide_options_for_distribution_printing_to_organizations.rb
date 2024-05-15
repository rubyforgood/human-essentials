class BackfillAddHideOptionsForDistributionPrintingToOrganizations < ActiveRecord::Migration[7.0]
  def change
    Organization.unscoped.in_batches do |relation|
      relation.update_all hide_value_columns_on_receipt: false, hide_package_column_on_receipt: false
      sleep(0.01)
    end
  end
end
