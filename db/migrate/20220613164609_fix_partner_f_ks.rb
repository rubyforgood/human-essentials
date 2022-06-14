class FixPartnerFKs < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :families, :partners
    add_foreign_key :families, :partner_profiles, column: :partner_id, validate: false
  end
end
