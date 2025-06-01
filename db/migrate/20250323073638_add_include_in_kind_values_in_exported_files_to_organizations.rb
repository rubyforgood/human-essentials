class AddIncludeInKindValuesInExportedFilesToOrganizations < ActiveRecord::Migration[8.0]
  def change
    add_column :organizations, :include_in_kind_values_in_exported_files, :boolean, default: false, null: false
  end
end
