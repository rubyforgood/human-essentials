class AddIncludeInKindValuesInExportedFilesToOrganizations < ActiveRecord::Migration[7.2]
  def change
    add_column :organizations, :include_in_kind_values_in_exported_files, :boolean
    change_column_default :organizations, :include_in_kind_values_in_exported_files, false
  end
end
