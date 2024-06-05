class BackfillIncludeSignatureOnOrganizations < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    Organization.update_all(signature_for_distribution_pdf: false)
  end
end
