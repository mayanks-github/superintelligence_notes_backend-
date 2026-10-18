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

ActiveRecord::Schema[8.1].define(version: 2026_10_18_120100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "app_settings", force: :cascade do |t|
    t.string "key", null: false
    t.jsonb "value", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_app_settings_on_key", unique: true
  end

  create_table "captures", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "source_id", null: false
    t.string "title", null: false
    t.string "origin", null: false
    t.text "summary_text"
    t.string "google_doc_id"
    t.string "external_url"
    t.string "video_id"
    t.string "video_url"
    t.string "video_title"
    t.string "thumbnail_url"
    t.datetime "saved_at", null: false
    t.string "storage", default: "google_docs", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["source_id"], name: "index_captures_on_source_id"
    t.index ["user_id", "google_doc_id"], name: "index_captures_on_user_id_and_google_doc_id", unique: true
    t.index ["user_id", "saved_at"], name: "index_captures_on_user_id_and_saved_at"
    t.index ["user_id", "source_id", "saved_at"], name: "index_captures_on_user_id_and_source_id_and_saved_at"
    t.index ["user_id"], name: "index_captures_on_user_id"
  end

  create_table "extension_sites", force: :cascade do |t|
    t.string "key", null: false
    t.string "name", null: false
    t.string "match_pattern", null: false
    t.string "aliases", default: [], null: false, array: true
    t.boolean "default_enabled", default: false, null: false
    t.boolean "enabled", default: true, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_extension_sites_on_key", unique: true
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "first_name", null: false
    t.string "last_name"
    t.string "email", null: false
    t.string "phone"
    t.string "timezone", default: "Asia/Kolkata", null: false
    t.string "bio"
    t.string "avatar_source", default: "generated", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_profiles_on_email"
    t.index ["user_id"], name: "index_profiles_on_user_id", unique: true
  end

  create_table "sources", force: :cascade do |t|
    t.string "key", null: false
    t.string "name", null: false
    t.string "kind", null: false
    t.string "host"
    t.string "brand_color", null: false
    t.boolean "supports_watch", default: false, null: false
    t.boolean "supports_manual_paste", default: true, null: false
    t.boolean "extension_capturable", default: false, null: false
    t.boolean "enabled", default: true, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_sources_on_key", unique: true
  end

  create_table "user_extension_sites", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "extension_site_id", null: false
    t.boolean "enabled", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["extension_site_id"], name: "index_user_extension_sites_on_extension_site_id"
    t.index ["user_id", "extension_site_id"], name: "index_user_extension_sites_uniqueness", unique: true
    t.index ["user_id"], name: "index_user_extension_sites_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "google_uid"
    t.text "google_refresh_token"
    t.text "google_access_token"
    t.datetime "google_token_expires_at"
    t.string "google_docs_folder_id"
    t.string "role", default: "user", null: false
    t.string "plan_tier", default: "free", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["google_uid"], name: "index_users_on_google_uid", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "captures", "sources"
  add_foreign_key "captures", "users"
  add_foreign_key "profiles", "users"
  add_foreign_key "user_extension_sites", "extension_sites"
  add_foreign_key "user_extension_sites", "users"
end
