class FixPartnerUserForeignKeys < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key "partner_requests", "users", column: "partner_user_id", validate: false
    add_foreign_key "users", "partner_profiles", column: "partner_id", validate: false
  end
end
