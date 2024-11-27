class AddSignatureFieldsFlagToOrganizations < ActiveRecord::Migration[7.0]
  def up
    add_column :organizations, :signature_for_distribution_pdf, :boolean
    change_column_default :organizations, :signature_for_distribution_pdf, false
  end

  def down
    remove_column :organizations, :signature_for_distribution_pdf
  end

end
