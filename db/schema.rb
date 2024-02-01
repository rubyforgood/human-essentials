# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2024_01_31_202431) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "category", ["US_County", "Other"]
  create_enum "kit_allocation_type", ["inventory_in", "inventory_out"]

  create_table "account_requests", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "organization_name", null: false
    t.string "organization_website"
    t.datetime "confirmed_at", precision: nil
    t.text "request_details", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "rejection_reason"
    t.string "status", default: "started", null: false
    t.bigint "ndbn_member_id"
    t.index ["status"], name: "index_account_requests_on_status"
  end

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
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
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "adjustments", id: :serial, force: :cascade do |t|
    t.integer "organization_id"
    t.integer "storage_location_id"
    t.text "comment"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "user_id"
    t.index ["organization_id"], name: "index_adjustments_on_organization_id"
    t.index ["storage_location_id"], name: "index_adjustments_on_storage_location_id"
    t.index ["user_id"], name: "index_adjustments_on_user_id"
  end

  create_table "annual_reports", force: :cascade do |t|
    t.bigint "organization_id"
    t.integer "year"
    t.json "all_reports"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_annual_reports_on_organization_id"
  end

  create_table "audits", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "organization_id"
    t.bigint "adjustment_id"
    t.bigint "storage_location_id"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["adjustment_id"], name: "index_audits_on_adjustment_id"
    t.index ["organization_id"], name: "index_audits_on_organization_id"
    t.index ["storage_location_id"], name: "index_audits_on_storage_location_id"
    t.index ["user_id"], name: "index_audits_on_user_id"
  end

  create_table "authorized_family_members", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.date "date_of_birth"
    t.string "gender"
    t.text "comments"
    t.bigint "family_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["family_id"], name: "index_authorized_family_members_on_family_id"
  end

  create_table "barcode_items", id: :serial, force: :cascade do |t|
    t.string "value"
    t.integer "barcodeable_id"
    t.integer "quantity"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "organization_id"
    t.string "barcodeable_type", default: "Item"
    t.index ["barcodeable_type", "barcodeable_id"], name: "index_barcode_items_on_barcodeable_type_and_barcodeable_id"
    t.index ["organization_id"], name: "index_barcode_items_on_organization_id"
  end

  create_table "base_items", force: :cascade do |t|
    t.string "name"
    t.string "category"
    t.integer "barcode_count"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "size"
    t.integer "item_count"
    t.string "partner_key"
  end

  create_table "broadcast_announcements", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "message"
    t.text "link"
    t.date "expiry"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organization_id"
    t.index ["organization_id"], name: "index_broadcast_announcements_on_organization_id"
    t.index ["user_id"], name: "index_broadcast_announcements_on_user_id"
  end

  create_table "child_item_requests", force: :cascade do |t|
    t.bigint "child_id"
    t.bigint "item_request_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "picked_up", default: false
    t.integer "quantity_picked_up"
    t.integer "picked_up_item_diaperid"
    t.integer "authorized_family_member_id"
    t.index ["child_id"], name: "index_child_item_requests_on_child_id"
    t.index ["item_request_id"], name: "index_child_item_requests_on_item_request_id"
  end

  create_table "children", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.date "date_of_birth"
    t.string "gender"
    t.jsonb "child_lives_with"
    t.jsonb "race"
    t.string "agency_child_id"
    t.jsonb "health_insurance"
    t.text "comments"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "family_id"
    t.integer "item_needed_diaperid"
    t.boolean "active", default: true
    t.boolean "archived"
    t.index ["family_id"], name: "index_children_on_family_id"
  end

  create_table "counties", force: :cascade do |t|
    t.string "name"
    t.string "region"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.enum "category", default: "US_County", null: false, enum_type: "category"
    t.index ["name", "region"], name: "index_counties_on_name_and_region", unique: true
    t.index ["name"], name: "index_counties_on_name"
    t.index ["region"], name: "index_counties_on_region"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "deprecated_feedback_messages", force: :cascade do |t|
    t.bigint "user_id"
    t.text "message"
    t.string "path"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "resolved"
    t.index ["user_id"], name: "index_deprecated_feedback_messages_on_user_id"
  end

  create_table "distributions", id: :serial, force: :cascade do |t|
    t.text "comment"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "storage_location_id"
    t.integer "partner_id"
    t.integer "organization_id"
    t.datetime "issued_at", precision: nil
    t.string "agency_rep"
    t.integer "state", default: 5, null: false
    t.boolean "reminder_email_enabled", default: false, null: false
    t.integer "delivery_method", default: 0, null: false
    t.decimal "shipping_cost", precision: 8, scale: 2
    t.index ["organization_id"], name: "index_distributions_on_organization_id"
    t.index ["partner_id"], name: "index_distributions_on_partner_id"
    t.index ["storage_location_id"], name: "index_distributions_on_storage_location_id"
  end

  create_table "donation_sites", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "address"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "organization_id"
    t.float "latitude"
    t.float "longitude"
    t.index ["latitude", "longitude"], name: "index_donation_sites_on_latitude_and_longitude"
    t.index ["organization_id"], name: "index_donation_sites_on_organization_id"
  end

  create_table "donations", id: :serial, force: :cascade do |t|
    t.string "source"
    t.integer "donation_site_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "storage_location_id"
    t.text "comment"
    t.integer "organization_id"
    t.integer "product_drive_participant_id"
    t.datetime "issued_at", precision: nil
    t.integer "money_raised"
    t.bigint "manufacturer_id"
    t.bigint "product_drive_id"
    t.index ["donation_site_id"], name: "index_donations_on_donation_site_id"
    t.index ["manufacturer_id"], name: "index_donations_on_manufacturer_id"
    t.index ["organization_id"], name: "index_donations_on_organization_id"
    t.index ["product_drive_id"], name: "index_donations_on_product_drive_id"
    t.index ["storage_location_id"], name: "index_donations_on_storage_location_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "type", null: false
    t.datetime "event_time", null: false
    t.jsonb "data"
    t.bigint "eventable_id"
    t.string "eventable_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organization_id"
    t.bigint "user_id"
    t.index ["organization_id", "event_time"], name: "index_events_on_organization_id_and_event_time"
    t.index ["organization_id"], name: "index_events_on_organization_id"
    t.index ["user_id"], name: "index_events_on_user_id"
  end

  create_table "families", force: :cascade do |t|
    t.string "guardian_first_name"
    t.string "guardian_last_name"
    t.string "guardian_zip_code"
    t.string "guardian_county"
    t.string "guardian_phone"
    t.string "case_manager"
    t.integer "home_adult_count"
    t.integer "home_child_count"
    t.integer "home_young_child_count"
    t.jsonb "sources_of_income"
    t.boolean "guardian_employed"
    t.jsonb "guardian_employment_type"
    t.decimal "guardian_monthly_pay"
    t.jsonb "guardian_health_insurance"
    t.text "comments"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "partner_id"
    t.boolean "military", default: false
    t.bigint "old_partner_id"
    t.boolean "archived", default: false
    t.index ["partner_id"], name: "index_families_on_partner_id"
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "inventory_discrepancies", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "event_id", null: false
    t.json "diff"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_inventory_discrepancies_on_event_id"
    t.index ["organization_id", "created_at"], name: "index_inventory_discrepancies_on_organization_id_and_created_at"
    t.index ["organization_id"], name: "index_inventory_discrepancies_on_organization_id"
  end

  create_table "inventory_items", id: :serial, force: :cascade do |t|
    t.integer "storage_location_id"
    t.integer "item_id"
    t.integer "quantity", default: 0
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "item_categories", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "organization_id"], name: "index_item_categories_on_name_and_organization_id", unique: true
  end

  create_table "item_categories_partner_groups", force: :cascade do |t|
    t.bigint "partner_group_id", null: false
    t.bigint "item_category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_category_id"], name: "index_item_categories_partner_groups_on_item_category_id"
    t.index ["partner_group_id"], name: "index_item_categories_partner_groups_on_partner_group_id"
  end

  create_table "item_requests", force: :cascade do |t|
    t.string "name"
    t.string "quantity"
    t.bigint "partner_request_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "partner_key"
    t.integer "item_id"
    t.integer "old_partner_request_id"
    t.index ["item_id"], name: "index_item_requests_on_item_id"
    t.index ["partner_request_id"], name: "index_item_requests_on_partner_request_id"
  end

  create_table "items", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "category"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "barcode_count"
    t.integer "organization_id"
    t.boolean "active", default: true
    t.string "partner_key"
    t.integer "value_in_cents", default: 0
    t.integer "package_size"
    t.integer "distribution_quantity"
    t.integer "on_hand_minimum_quantity", default: 0, null: false
    t.integer "on_hand_recommended_quantity"
    t.boolean "visible_to_partners", default: true, null: false
    t.integer "kit_id"
    t.integer "item_category_id"
    t.index ["kit_id"], name: "index_items_on_kit_id"
    t.index ["organization_id"], name: "index_items_on_organization_id"
    t.index ["partner_key"], name: "index_items_on_partner_key"
    t.check_constraint "distribution_quantity >= 0", name: "distribution_quantity_nonnegative"
  end

  create_table "kit_allocations", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "storage_location_id", null: false
    t.bigint "kit_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.enum "kit_allocation_type", default: "inventory_in", null: false, enum_type: "kit_allocation_type"
    t.index ["kit_id"], name: "index_kit_allocations_on_kit_id"
    t.index ["organization_id"], name: "index_kit_allocations_on_organization_id"
    t.index ["storage_location_id"], name: "index_kit_allocations_on_storage_location_id"
  end

  create_table "kits", force: :cascade do |t|
    t.string "name", null: false
    t.integer "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true
    t.boolean "visible_to_partners", default: true, null: false
    t.integer "value_in_cents", default: 0
    t.index ["name", "organization_id"], name: "index_kits_on_name_and_organization_id", unique: true
    t.index ["organization_id"], name: "index_kits_on_organization_id"
  end

  create_table "line_items", id: :serial, force: :cascade do |t|
    t.integer "quantity"
    t.integer "item_id"
    t.integer "itemizable_id"
    t.string "itemizable_type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["itemizable_id", "itemizable_type"], name: "index_line_items_on_itemizable_id_and_itemizable_type"
  end

  create_table "manufacturers", force: :cascade do |t|
    t.string "name"
    t.bigint "organization_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["organization_id"], name: "index_manufacturers_on_organization_id"
  end

  create_table "ndbn_members", primary_key: "ndbn_member_id", force: :cascade do |t|
    t.string "account_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "organizations", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "short_name"
    t.string "email"
    t.string "url"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "intake_location"
    t.string "street"
    t.string "city"
    t.string "state"
    t.string "zipcode"
    t.float "latitude"
    t.float "longitude"
    t.integer "reminder_day"
    t.integer "deadline_day"
    t.text "invitation_text"
    t.integer "default_storage_location"
    t.text "partner_form_fields", default: [], array: true
    t.integer "account_request_id"
    t.boolean "repackage_essentials", default: false, null: false
    t.boolean "distribute_monthly", default: false, null: false
    t.bigint "ndbn_member_id"
    t.boolean "enable_child_based_requests", default: true, null: false
    t.boolean "enable_individual_requests", default: true, null: false
    t.boolean "enable_quantity_based_requests", default: true, null: false
    t.boolean "ytd_on_distribution_printout", default: true, null: false
    t.boolean "use_single_step_invite_and_approve_partner_process", default: false, null: false
    t.index ["latitude", "longitude"], name: "index_organizations_on_latitude_and_longitude"
    t.index ["short_name"], name: "index_organizations_on_short_name"
  end

  create_table "partner_forms", force: :cascade do |t|
    t.integer "essentials_bank_id"
    t.text "sections", default: [], array: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "partner_groups", force: :cascade do |t|
    t.bigint "organization_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "send_reminders", default: false, null: false
    t.integer "reminder_day"
    t.integer "deadline_day"
    t.index ["name", "organization_id"], name: "index_partner_groups_on_name_and_organization_id", unique: true
    t.index ["organization_id"], name: "index_partner_groups_on_organization_id"
    t.check_constraint "deadline_day <= 28", name: "deadline_day_of_month_check"
    t.check_constraint "reminder_day <= 28", name: "reminder_day_of_month_check"
  end

  create_table "partner_profiles", force: :cascade do |t|
    t.bigint "essentials_bank_id"
    t.text "application_data"
    t.integer "partner_id"
    t.string "partner_status", default: "pending"
    t.string "name"
    t.string "distributor_type"
    t.string "agency_type"
    t.text "agency_mission"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "state"
    t.string "zip_code"
    t.string "website"
    t.string "facebook"
    t.string "twitter"
    t.integer "founded"
    t.boolean "form_990"
    t.string "program_name"
    t.text "program_description"
    t.string "program_age"
    t.boolean "case_management"
    t.boolean "evidence_based"
    t.text "evidence_based_description"
    t.text "program_client_improvement"
    t.string "essentials_use"
    t.string "receives_essentials_from_other"
    t.boolean "currently_provide_diapers"
    t.boolean "turn_away_child_care"
    t.string "program_address1"
    t.string "program_address2"
    t.string "program_city"
    t.string "program_state"
    t.integer "program_zip_code"
    t.string "client_capacity"
    t.text "incorporate_plan"
    t.boolean "responsible_staff_position"
    t.boolean "storage_space"
    t.text "describe_storage_space"
    t.boolean "trusted_pickup"
    t.boolean "income_requirement_desc"
    t.boolean "serve_income_circumstances"
    t.boolean "income_verification"
    t.boolean "internal_db"
    t.boolean "maac"
    t.integer "population_black"
    t.integer "population_white"
    t.integer "population_hispanic"
    t.integer "population_asian"
    t.integer "population_american_indian"
    t.integer "population_island"
    t.integer "population_multi_racial"
    t.integer "population_other"
    t.string "zips_served"
    t.integer "at_fpl_or_below"
    t.integer "above_1_2_times_fpl"
    t.integer "greater_2_times_fpl"
    t.integer "poverty_unknown"
    t.string "ages_served"
    t.string "executive_director_name"
    t.string "executive_director_phone"
    t.string "executive_director_email"
    t.string "primary_contact_name"
    t.string "primary_contact_phone"
    t.string "primary_contact_mobile"
    t.string "primary_contact_email"
    t.string "pick_up_method"
    t.string "pick_up_name"
    t.string "pick_up_phone"
    t.string "pick_up_email"
    t.string "distribution_times"
    t.string "new_client_times"
    t.string "more_docs_required"
    t.string "sources_of_funding"
    t.string "sources_of_diapers"
    t.string "essentials_budget"
    t.string "essentials_funding_source"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "other_agency_type"
    t.string "status_in_diaper_base"
    t.boolean "enable_child_based_requests", default: true, null: false
    t.boolean "enable_individual_requests", default: true, null: false
    t.string "instagram"
    t.boolean "no_social_media_presence"
    t.boolean "enable_quantity_based_requests", default: true, null: false
    t.index ["essentials_bank_id"], name: "index_partners_on_essentials_bank_id"
  end

  create_table "partner_requests", force: :cascade do |t|
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

  create_table "partner_served_areas", force: :cascade do |t|
    t.bigint "partner_profile_id", null: false
    t.bigint "county_id", null: false
    t.integer "client_share"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["county_id"], name: "index_partner_served_areas_on_county_id"
    t.index ["partner_profile_id"], name: "index_partner_served_areas_on_partner_profile_id"
  end

  create_table "partner_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "invitation_token"
    t.datetime "invitation_created_at", precision: nil
    t.datetime "invitation_sent_at", precision: nil
    t.datetime "invitation_accepted_at", precision: nil
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.bigint "invited_by_id"
    t.integer "invitations_count", default: 0
    t.bigint "partner_id"
    t.string "name"
    t.index ["email"], name: "index_partner_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_partner_users_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_partner_users_on_invitations_count"
    t.index ["invited_by_id"], name: "index_partner_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_partner_users_on_invited_by"
    t.index ["partner_id"], name: "index_partner_users_on_partner_id"
    t.index ["reset_password_token"], name: "index_partner_users_on_reset_password_token", unique: true
  end

  create_table "partners", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "organization_id"
    t.integer "status", default: 0
    t.boolean "send_reminders", default: false, null: false
    t.text "notes"
    t.integer "quota"
    t.bigint "partner_group_id"
    t.bigint "default_storage_location_id"
    t.index ["default_storage_location_id"], name: "index_partners_on_default_storage_location_id"
    t.index ["organization_id"], name: "index_partners_on_organization_id"
    t.index ["partner_group_id"], name: "index_partners_on_partner_group_id"
  end

  create_table "product_drive_participants", id: :serial, force: :cascade do |t|
    t.string "contact_name"
    t.string "email"
    t.string "phone"
    t.string "comment"
    t.integer "organization_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "address"
    t.string "business_name"
    t.float "latitude"
    t.float "longitude"
    t.index ["latitude", "longitude"], name: "index_product_drive_participants_on_latitude_and_longitude"
  end

  create_table "product_drives", force: :cascade do |t|
    t.string "name"
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "organization_id"
    t.boolean "virtual", default: false, null: false
    t.index ["organization_id"], name: "index_product_drives_on_organization_id"
  end

  create_table "purchases", force: :cascade do |t|
    t.string "purchased_from"
    t.text "comment"
    t.integer "organization_id"
    t.integer "storage_location_id"
    t.integer "amount_spent_in_cents"
    t.datetime "issued_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "vendor_id"
    t.integer "amount_spent_on_diapers_cents", default: 0, null: false
    t.integer "amount_spent_on_adult_incontinence_cents", default: 0, null: false
    t.integer "amount_spent_on_other_cents", default: 0, null: false
    t.integer "amount_spent_on_period_supplies_cents", default: 0, null: false
    t.index ["organization_id"], name: "index_purchases_on_organization_id"
    t.index ["storage_location_id"], name: "index_purchases_on_storage_location_id"
  end

  create_table "questions", force: :cascade do |t|
    t.string "title", null: false
    t.boolean "for_partners", default: true, null: false
    t.boolean "for_banks", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "requests", force: :cascade do |t|
    t.bigint "partner_id"
    t.bigint "organization_id"
    t.jsonb "request_items", default: {}
    t.text "comments"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "distribution_id"
    t.integer "status", default: 0
    t.datetime "discarded_at", precision: nil
    t.text "discard_reason"
    t.integer "partner_user_id"
    t.index ["discarded_at"], name: "index_requests_on_discarded_at"
    t.index ["distribution_id"], name: "index_requests_on_distribution_id", unique: true
    t.index ["organization_id"], name: "index_requests_on_organization_id"
    t.index ["partner_id"], name: "index_requests_on_partner_id"
    t.index ["status"], name: "index_requests_on_status"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.bigint "resource_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "old_resource_id"
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource"
  end

  create_table "storage_locations", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "address"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "organization_id"
    t.float "latitude"
    t.float "longitude"
    t.integer "square_footage"
    t.string "warehouse_type"
    t.string "time_zone", default: "America/Los_Angeles", null: false
    t.datetime "discarded_at"
    t.index ["discarded_at"], name: "index_storage_locations_on_discarded_at"
    t.index ["latitude", "longitude"], name: "index_storage_locations_on_latitude_and_longitude"
    t.index ["organization_id"], name: "index_storage_locations_on_organization_id"
  end

  create_table "transfers", id: :serial, force: :cascade do |t|
    t.integer "from_id"
    t.integer "to_id"
    t.string "comment"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "organization_id"
    t.index ["organization_id"], name: "index_transfers_on_organization_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "organization_id"
    t.string "invitation_token"
    t.datetime "invitation_created_at", precision: nil
    t.datetime "invitation_sent_at", precision: nil
    t.datetime "invitation_accepted_at", precision: nil
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.integer "invited_by_id"
    t.integer "invitations_count", default: 0
    t.boolean "organization_admin"
    t.string "name", default: "Name Not Provided", null: false
    t.boolean "super_admin", default: false
    t.datetime "last_request_at", precision: nil
    t.datetime "discarded_at", precision: nil
    t.string "provider"
    t.string "uid"
    t.bigint "partner_id"
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_users_on_invitations_count"
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by_type_and_invited_by_id"
    t.index ["partner_id"], name: "index_users_on_partner_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "users_roles", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "role_id"
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

  create_table "vendors", force: :cascade do |t|
    t.string "contact_name"
    t.string "email"
    t.string "phone"
    t.string "comment"
    t.integer "organization_id"
    t.string "address"
    t.string "business_name"
    t.float "latitude"
    t.float "longitude"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["latitude", "longitude"], name: "index_vendors_on_latitude_and_longitude"
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type"
    t.string "{:null=>false}"
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.jsonb "object"
    t.datetime "created_at", precision: nil
    t.jsonb "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "account_requests", "ndbn_members", primary_key: "ndbn_member_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "adjustments", "organizations"
  add_foreign_key "adjustments", "storage_locations"
  add_foreign_key "adjustments", "users"
  add_foreign_key "annual_reports", "organizations"
  add_foreign_key "authorized_family_members", "families"
  add_foreign_key "broadcast_announcements", "users"
  add_foreign_key "child_item_requests", "children"
  add_foreign_key "child_item_requests", "item_requests"
  add_foreign_key "children", "families"
  add_foreign_key "distributions", "partners"
  add_foreign_key "distributions", "storage_locations"
  add_foreign_key "donations", "manufacturers"
  add_foreign_key "donations", "product_drives"
  add_foreign_key "donations", "storage_locations"
  add_foreign_key "families", "partners"
  add_foreign_key "inventory_discrepancies", "events"
  add_foreign_key "inventory_discrepancies", "organizations"
  add_foreign_key "item_categories", "organizations"
  add_foreign_key "item_categories_partner_groups", "item_categories"
  add_foreign_key "item_categories_partner_groups", "partner_groups"
  add_foreign_key "items", "item_categories"
  add_foreign_key "items", "kits"
  add_foreign_key "kit_allocations", "kits"
  add_foreign_key "kit_allocations", "organizations"
  add_foreign_key "kit_allocations", "storage_locations"
  add_foreign_key "kits", "organizations"
  add_foreign_key "manufacturers", "organizations"
  add_foreign_key "organizations", "account_requests"
  add_foreign_key "organizations", "ndbn_members", primary_key: "ndbn_member_id"
  add_foreign_key "partner_groups", "organizations"
  add_foreign_key "partner_requests", "users", column: "partner_user_id"
  add_foreign_key "partner_served_areas", "counties"
  add_foreign_key "partner_served_areas", "partner_profiles"
  add_foreign_key "partners", "storage_locations", column: "default_storage_location_id"
  add_foreign_key "product_drives", "organizations"
  add_foreign_key "requests", "distributions"
  add_foreign_key "requests", "organizations"
  add_foreign_key "requests", "partners"
end
