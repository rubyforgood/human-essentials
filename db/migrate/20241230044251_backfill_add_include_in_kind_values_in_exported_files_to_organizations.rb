class BackfillAddIncludeInKindValuesInExportedFilesToOrganizations < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!
  def change
    Organization.unscoped.in_batches do |relation|
      relation.update_all include_in_kind_values_in_exported_files: false
      sleep(0.01)
    end
  end
end
