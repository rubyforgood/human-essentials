class EnforceNotNullOnIncludeInKindValuesInExportedFilesInOrganizations < ActiveRecord::Migration[8.0]
  def up
    change_column_null :organizations, :include_in_kind_values_in_exported_files, false
    change_column_default :organizations, :include_in_kind_values_in_exported_files, false
    remove_check_constraint :organizations, name: "include_in_kind_values_in_exported_files_not_null"
  end

  def down
    add_check_constraint :organizations, "include_in_kind_values_in_exported_files IS NOT NULL", name: "include_in_kind_values_in_exported_files_not_null", validate: false
    change_column_default :organizations, :include_in_kind_values_in_exported_files, nil
    change_column_null :organizations, :include_in_kind_values_in_exported_files, true
  end
end
