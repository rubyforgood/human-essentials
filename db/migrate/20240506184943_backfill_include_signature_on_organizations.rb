class BackfillIncludeSignatureOnOrganizations < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    Organization.update_all(include_signature_fields_on_distribution_printout: false)
  end
end
