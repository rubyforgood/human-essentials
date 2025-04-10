class BackfillFalseToIncludeInKindValuesInExportedFilesInOrganizations < ActiveRecord::Migration[8.0]
  def up
    Organization.unscoped.in_batches do |relation|
      relation.update_all include_in_kind_values_in_exported_files: false
      sleep(0.01)
    end

    validate_check_constraint :organizations, name: "include_in_kind_values_in_exported_files_not_null"
  end

  def down

  end
end
