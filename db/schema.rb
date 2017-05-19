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

ActiveRecord::Schema.define(version: 20170519161045) do

  create_table "barcode_items", force: :cascade do |t|
    t.string   "value"
    t.integer  "item_id"
    t.integer  "quantity"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "organization_id"
    t.index ["organization_id"], name: "index_barcode_items_on_organization_id", using: :btree
  end

  create_table "distributions", force: :cascade do |t|
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "inventory_id"
    t.integer  "partner_id"
    t.integer  "organization_id"
    t.index ["inventory_id"], name: "index_distributions_on_inventory_id", using: :btree
    t.index ["organization_id"], name: "index_distributions_on_organization_id", using: :btree
    t.index ["partner_id"], name: "index_distributions_on_partner_id", using: :btree
  end

  create_table "donations", force: :cascade do |t|
    t.string   "source"
    t.boolean  "completed",           default: false
    t.integer  "dropoff_location_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "inventory_id"
    t.text     "comment"
    t.integer  "organization_id"
    t.index ["dropoff_location_id"], name: "index_donations_on_dropoff_location_id", using: :btree
    t.index ["inventory_id"], name: "index_donations_on_inventory_id", using: :btree
    t.index ["organization_id"], name: "index_donations_on_organization_id", using: :btree
  end

  create_table "dropoff_locations", force: :cascade do |t|
    t.string   "name"
    t.string   "address"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organization_id"
    t.index ["organization_id"], name: "index_dropoff_locations_on_organization_id", using: :btree
  end

  create_table "inventories", force: :cascade do |t|
    t.string   "name"
    t.string   "address"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organization_id"
    t.index ["organization_id"], name: "index_inventories_on_organization_id", using: :btree
  end

  create_table "inventory_items", force: :cascade do |t|
    t.integer  "inventory_id"
    t.integer  "item_id"
    t.integer  "quantity"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "items", force: :cascade do |t|
    t.string   "name"
    t.string   "category"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "barcode_count"
    t.integer  "organization_id"
    t.index ["organization_id"], name: "index_items_on_organization_id", using: :btree
  end

  create_table "line_items", force: :cascade do |t|
    t.integer  "quantity"
    t.integer  "item_id"
    t.integer  "itemizable_id"
    t.string   "itemizable_type"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.index ["itemizable_id", "itemizable_type"], name: "index_line_items_on_itemizable_id_and_itemizable_type", using: :btree
  end

  create_table "organizations", force: :cascade do |t|
    t.string   "name"
    t.string   "short_name"
    t.text     "address"
    t.string   "email"
    t.string   "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["short_name"], name: "index_organizations_on_short_name", using: :btree
  end

  create_table "partners", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organization_id"
    t.index ["organization_id"], name: "index_partners_on_organization_id", using: :btree
  end

  create_table "transfers", force: :cascade do |t|
    t.integer  "from_id"
    t.integer  "to_id"
    t.string   "comment"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "organization_id"
    t.index ["organization_id"], name: "index_transfers_on_organization_id", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  end

  add_foreign_key "distributions", "inventories"
  add_foreign_key "distributions", "partners"
  add_foreign_key "donations", "inventories"

end
