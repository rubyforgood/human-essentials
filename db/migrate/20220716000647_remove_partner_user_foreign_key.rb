class RemovePartnerUserForeignKey < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key "partner_requests", "partner_users"
  end
end
