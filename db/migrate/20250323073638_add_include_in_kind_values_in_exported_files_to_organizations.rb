class AddIncludeInKindValuesInExportedFilesToOrganizations < ActiveRecord::Migration[8.0]
  def change
    add_column :organizations, :include_in_kind_values_in_exported_files, :boolean
    add_check_constraint :organizations, "include_in_kind_values_in_exported_files IS NOT NULL", name: "include_in_kind_values_in_exported_files_not_null", validate: false
  end
end
