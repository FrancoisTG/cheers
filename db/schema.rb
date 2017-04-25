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

ActiveRecord::Schema.define(version: 20170425154901) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "confirmations", force: :cascade do |t|
    t.string   "leaving_address"
    t.string   "transportation"
    t.integer  "user_id"
    t.integer  "hangout_id"
    t.integer  "place_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.float    "latitude"
    t.float    "longitude"
    t.index ["hangout_id"], name: "index_confirmations_on_hangout_id", using: :btree
    t.index ["place_id"], name: "index_confirmations_on_place_id", using: :btree
    t.index ["user_id"], name: "index_confirmations_on_user_id", using: :btree
  end

  create_table "hangouts", force: :cascade do |t|
    t.string   "title"
    t.datetime "date"
    t.string   "category"
    t.string   "center_address"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.integer  "user_id"
    t.integer  "place_id"
    t.float    "latitude"
    t.float    "longitude"
    t.index ["place_id"], name: "index_hangouts_on_place_id", using: :btree
    t.index ["user_id"], name: "index_hangouts_on_user_id", using: :btree
  end

  create_table "places", force: :cascade do |t|
    t.string   "address"
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float    "latitude"
    t.float    "longitude"
  end

  create_table "places_options", force: :cascade do |t|
    t.integer  "hangout_id"
    t.integer  "place_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hangout_id"], name: "index_places_options_on_hangout_id", using: :btree
    t.index ["place_id"], name: "index_places_options_on_place_id", using: :btree
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
    t.string   "first_name"
    t.string   "last_name"
    t.string   "avatar_url"
    t.string   "facebook_picture_url"
    t.string   "token"
    t.datetime "token_expiry"
    t.string   "provider"
    t.string   "uid"
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  end

  add_foreign_key "confirmations", "hangouts"
  add_foreign_key "confirmations", "places"
  add_foreign_key "confirmations", "users"
  add_foreign_key "hangouts", "places"
  add_foreign_key "hangouts", "users"
  add_foreign_key "places_options", "hangouts"
  add_foreign_key "places_options", "places"
end
