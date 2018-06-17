# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_06_10_152822) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "adjustments", force: :cascade do |t|
    t.integer "organization_id"
    t.integer "storage_location_id"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_adjustments_on_organization_id"
    t.index ["storage_location_id"], name: "index_adjustments_on_storage_location_id"
  end

  create_table "barcode_items", force: :cascade do |t|
    t.string "value"
    t.integer "barcodeable_id"
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "organization_id"
    t.boolean "global", default: false
    t.string "barcodeable_type", default: "Item"
    t.index ["barcodeable_type", "barcodeable_id"], name: "index_barcode_items_on_barcodeable_type_and_barcodeable_id"
    t.index ["organization_id"], name: "index_barcode_items_on_organization_id"
  end

  create_table "canonical_items", force: :cascade do |t|
    t.string "name"
    t.string "category"
    t.integer "barcode_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "size"
    t.integer "item_count"
  end

  create_table "diaper_drive_participants", force: :cascade do |t|
    t.string "name"
    t.string "contact_name"
    t.string "email"
    t.string "phone"
    t.string "comment"
    t.integer "organization_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "address"
    t.string "business_name"
  end

  create_table "distributions", force: :cascade do |t|
    t.text "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "storage_location_id"
    t.integer "partner_id"
    t.integer "organization_id"
    t.datetime "issued_at"
    t.string "agency_rep"
    t.index ["organization_id"], name: "index_distributions_on_organization_id"
    t.index ["partner_id"], name: "index_distributions_on_partner_id"
    t.index ["storage_location_id"], name: "index_distributions_on_storage_location_id"
  end

  create_table "donation_sites", force: :cascade do |t|
    t.string "name"
    t.string "address"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "organization_id"
    t.index ["organization_id"], name: "index_donation_sites_on_organization_id"
  end

  create_table "donations", force: :cascade do |t|
    t.string "source"
    t.integer "donation_site_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "storage_location_id"
    t.text "comment"
    t.integer "organization_id"
    t.integer "diaper_drive_participant_id"
    t.datetime "issued_at"
    t.index ["donation_site_id"], name: "index_donations_on_donation_site_id"
    t.index ["organization_id"], name: "index_donations_on_organization_id"
    t.index ["storage_location_id"], name: "index_donations_on_storage_location_id"
  end

  create_table "inventory_items", force: :cascade do |t|
    t.integer "storage_location_id"
    t.integer "item_id"
    t.integer "quantity", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "items", force: :cascade do |t|
    t.string "name"
    t.string "category"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "barcode_count"
    t.integer "organization_id"
    t.integer "canonical_item_id"
    t.boolean "active", default: true
    t.index ["organization_id"], name: "index_items_on_organization_id"
  end

  create_table "line_items", force: :cascade do |t|
    t.integer "quantity"
    t.integer "item_id"
    t.integer "itemizable_id"
    t.string "itemizable_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["itemizable_id", "itemizable_type"], name: "index_line_items_on_itemizable_id_and_itemizable_type"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name"
    t.string "short_name"
    t.string "email"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "intake_location"
    t.string "street"
    t.string "city"
    t.string "state"
    t.string "zipcode"
    t.index ["short_name"], name: "index_organizations_on_short_name"
  end

  create_table "partners", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "organization_id"
    t.index ["organization_id"], name: "index_partners_on_organization_id"
  end

  create_table "purchases", force: :cascade do |t|
    t.string "purchased_from"
    t.text "comment"
    t.integer "organization_id"
    t.integer "storage_location_id"
    t.integer "amount_spent"
    t.datetime "issued_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_purchases_on_organization_id"
    t.index ["storage_location_id"], name: "index_purchases_on_storage_location_id"
  end

  create_table "storage_locations", force: :cascade do |t|
    t.string "name"
    t.string "address"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "organization_id"
    t.index ["organization_id"], name: "index_storage_locations_on_organization_id"
  end

  create_table "transfers", force: :cascade do |t|
    t.integer "from_id"
    t.integer "to_id"
    t.string "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "organization_id"
    t.index ["organization_id"], name: "index_transfers_on_organization_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "organization_id"
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.integer "invited_by_id"
    t.integer "invitations_count", default: 0
    t.boolean "organization_admin"
    t.string "name", default: "CHANGEME", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_users_on_invitations_count"
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by_type_and_invited_by_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "adjustments", "organizations"
  add_foreign_key "adjustments", "storage_locations"
  add_foreign_key "distributions", "partners"
  add_foreign_key "distributions", "storage_locations"
  add_foreign_key "donations", "storage_locations"
end
