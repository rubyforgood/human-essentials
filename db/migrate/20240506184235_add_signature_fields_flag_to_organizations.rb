class AddSignatureFieldsFlagToOrganizations < ActiveRecord::Migration[7.0]
  def up
    add_column :organizations, :include_signature_fields_on_distribution_printout, :boolean
    change_column_default :organizations, :include_signature_fields_on_distribution_printout, false
  end

  def down
    remove_column :organizations, :include_signature_fields_on_distribution_printout
  end

end
