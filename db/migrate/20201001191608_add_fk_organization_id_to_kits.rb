class AddFkOrganizationIdToKits < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :kits, :organizations
  end
end
