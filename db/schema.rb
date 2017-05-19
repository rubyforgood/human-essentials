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

ActiveRecord::Schema.define(version: 20170519134505) do

  create_table "barcode_items", force: :cascade do |t|
    t.string   "value"
    t.integer  "item_id"
    t.integer  "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "containers", force: :cascade do |t|
    t.integer  "quantity"
    t.integer  "item_id"
    t.integer  "itemizable_id"
    t.string   "itemizable_type"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.index ["itemizable_id", "itemizable_type"], name: "index_containers_on_itemizable_id_and_itemizable_type"
  end

  create_table "distributions", force: :cascade do |t|
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "inventory_id"
    t.integer  "partner_id"
    t.index ["inventory_id"], name: "index_distributions_on_inventory_id"
    t.index ["partner_id"], name: "index_distributions_on_partner_id"
  end

  create_table "donations", force: :cascade do |t|
    t.string   "source"
    t.boolean  "completed",           default: false
    t.integer  "dropoff_location_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "inventory_id"
    t.index ["dropoff_location_id"], name: "index_donations_on_dropoff_location_id"
    t.index ["inventory_id"], name: "index_donations_on_inventory_id"
  end

  create_table "dropoff_locations", force: :cascade do |t|
    t.string   "name"
    t.string   "address"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "inventories", force: :cascade do |t|
    t.string   "name"
    t.string   "address"
    t.datetime "created_at"
    t.datetime "updated_at"
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
  end

  create_table "organizations", force: :cascade do |t|
    t.string   "name"
    t.string   "short_name"
    t.text     "address"
    t.string   "email"
    t.string   "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["short_name"], name: "index_organizations_on_short_name"
  end

  create_table "partners", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transfers", force: :cascade do |t|
    t.integer  "from_id"
    t.integer  "to_id"
    t.string   "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
