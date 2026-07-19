class DropPartnerRequests < ActiveRecord::Migration[8.0]
  def change
    drop_table :partner_requests do |t|
      t.text "comments"
      t.bigint "partner_id"
      t.bigint "organization_id"
      t.boolean "sent", default: false, null: false
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.boolean "for_families"
      t.integer "partner_user_id"

      t.index ["organization_id"], name: "index_partner_requests_on_organization_id"
      t.index ["partner_id"], name: "index_partner_requests_on_partner_id"
    end
  end
end
