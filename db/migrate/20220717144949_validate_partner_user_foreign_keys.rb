class ValidatePartnerUserForeignKeys < ActiveRecord::Migration[7.0]
  def change
    validate_foreign_key "partner_requests", "users"
    validate_foreign_key "users", "partner_profiles", column: "partner_id"
  end
end
