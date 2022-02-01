# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_02_01_015710) do

  create_table "api_statistics", force: true do |t|
    t.string   "ip_address"
    t.text     "query"
    t.text     "user_agent"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bills", force: true do |t|
    t.string   "official_id"
    t.text     "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "title"
  end

  create_table "bills_divisions", id: false, force: true do |t|
    t.integer "division_id", null: false
    t.integer "bill_id",     null: false
  end

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree
  end

  create_table "division_infos", force: true do |t|
    t.integer  "division_id",      null: false
    t.integer  "rebellions",       null: false
    t.integer  "tells",            null: false
    t.integer  "turnout",          null: false
    t.integer  "possible_turnout", null: false
    t.integer  "aye_majority",     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["division_id"], name: "division_id", using: :btree
  end

  create_table "divisions", force: true do |t|
    t.boolean  "valid"
    t.date     "date",                      null: false
    t.integer  "number",                    null: false
    t.string   "house",                     null: false
    t.text     "name",                      null: false
    t.text     "source_url",                null: false
    t.text     "debate_url",                null: false
    t.text     "motion",                    null: false
    t.string   "clock_time"
    t.text     "source_gid",                null: false
    t.text     "debate_gid",                null: false
    t.boolean  "markdown",   default: true, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["date", "number", "house"], name: "division_date_2", unique: true, using: :btree
    t.index ["date"], name: "division_date", using: :btree
    t.index ["house"], name: "house", using: :btree
    t.index ["id", "date", "clock_time"], name: "index_divisions_on_id_and_date_and_clock_time", using: :btree
    t.index ["number"], name: "division_number", using: :btree
  end

  create_table "electorates", force: true do |t|
    t.string   "name",       limit: 100,                        null: false
    t.boolean  "main_name",                                     null: false
    t.date     "from_date",              default: '1000-01-01', null: false
    t.date     "to_date",                default: '9999-12-31', null: false
    t.string   "house",                  default: "commons",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["from_date"], name: "from_date", using: :btree
    t.index ["id", "name"], name: "cons_id", using: :btree
    t.index ["name"], name: "name", using: :btree
    t.index ["to_date"], name: "to_date", using: :btree
  end

  create_table "flipper_features", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8_unicode_ci" do |t|
    t.string   "key",        null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true, using: :btree
  end

  create_table "flipper_gates", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8_unicode_ci" do |t|
    t.string   "feature_key", null: false
    t.string   "key",         null: false
    t.string   "value"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true, using: :btree
  end

  create_table "member_distances", force: true do |t|
    t.integer  "member1_id",              null: false
    t.integer  "member2_id",              null: false
    t.integer  "nvotessame"
    t.integer  "nvotesdiffer"
    t.integer  "nvotesabsent"
    t.float    "distance_a",   limit: 24
    t.float    "distance_b",   limit: 24
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["member1_id", "member2_id"], name: "mp_id1_2", unique: true, using: :btree
    t.index ["member1_id"], name: "mp_id1", using: :btree
    t.index ["member2_id"], name: "mp_id2", using: :btree
  end

  create_table "member_infos", force: true do |t|
    t.integer  "member_id",      null: false
    t.integer  "rebellions",     null: false
    t.integer  "tells",          null: false
    t.integer  "votes_attended", null: false
    t.integer  "votes_possible", null: false
    t.integer  "aye_majority",   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["member_id"], name: "mp_id", using: :btree
  end

  create_table "members", force: true do |t|
    t.string   "gid",            limit: 100,                        null: false
    t.text     "source_gid",                                        null: false
    t.string   "first_name",     limit: 100,                        null: false
    t.string   "last_name",      limit: 100,                        null: false
    t.string   "title",          limit: 50,                         null: false
    t.string   "constituency",   limit: 100,                        null: false
    t.string   "party",          limit: 100,                        null: false
    t.string   "house",                                             null: false
    t.date     "entered_house",              default: '1000-01-01', null: false
    t.date     "left_house",                 default: '9999-12-31', null: false
    t.string   "entered_reason", limit: 16,  default: "unknown",    null: false
    t.string   "left_reason",    limit: 28,  default: "unknown",    null: false
    t.integer  "person_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["entered_house"], name: "entered_house", using: :btree
    t.index ["gid"], name: "gid", using: :btree
    t.index ["house"], name: "house", using: :btree
    t.index ["left_house"], name: "left_house", using: :btree
    t.index ["party"], name: "party", using: :btree
    t.index ["person_id"], name: "person", using: :btree
    t.index ["title", "first_name", "last_name", "constituency", "entered_house", "left_house", "house"], name: "title", unique: true, using: :btree
  end

  create_table "offices", force: true do |t|
    t.string   "dept",                                  null: false
    t.string   "position",                              null: false
    t.string   "responsibility",                        null: false
    t.date     "from_date",      default: '1000-01-01', null: false
    t.date     "to_date",        default: '9999-12-31', null: false
    t.integer  "person_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["person_id"], name: "person", using: :btree
  end

  create_table "people", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "small_image_url"
    t.text     "large_image_url"
  end

  create_table "policies", force: true do |t|
    t.string   "name",        limit: 100, null: false
    t.integer  "user_id",                 null: false
    t.text     "description",             null: false
    t.integer  "private",     limit: 1,   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["id", "name", "user_id"], name: "dream_id", unique: true, using: :btree
    t.index ["user_id"], name: "user_id", using: :btree
  end

  create_table "policy_divisions", force: true do |t|
    t.integer  "policy_id",              null: false
    t.string   "vote",        limit: 10, null: false
    t.integer  "division_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["division_id", "policy_id"], name: "index_policy_divisions_on_division_id_and_policy_id", unique: true, using: :btree
    t.index ["division_id"], name: "index_policy_divisions_on_division_id", using: :btree
    t.index ["policy_id"], name: "dream_id", using: :btree
  end

  create_table "policy_person_distances", force: true do |t|
    t.integer  "policy_id",                     null: false
    t.integer  "person_id",                     null: false
    t.integer  "nvotessame"
    t.integer  "nvotessamestrong"
    t.integer  "nvotesdiffer"
    t.integer  "nvotesdifferstrong"
    t.integer  "nvotesabsent"
    t.integer  "nvotesabsentstrong"
    t.float    "distance_a",         limit: 24
    t.float    "distance_b",         limit: 24
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["person_id"], name: "person", using: :btree
    t.index ["policy_id", "person_id"], name: "dream_id_2", unique: true, using: :btree
    t.index ["policy_id"], name: "dream_id", using: :btree
  end

  create_table "users", force: true do |t|
    t.text     "name", null: false
    t.text     "email"
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "api_key"
    t.boolean  "admin",                                   default: false, null: false
    t.index ["api_key"], name: "index_users_on_api_key", unique: true, using: :btree
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  end

  create_table "versions", force: true do |t|
    t.string   "item_type",      null: false
    t.integer  "item_id",        null: false
    t.string   "event",          null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.integer  "policy_id"
    t.text     "object_changes"
    t.integer  "division_id"
    t.index ["division_id"], name: "index_versions_on_division_id", using: :btree
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree
    t.index ["policy_id"], name: "index_versions_on_policy_id", using: :btree
  end

  create_table "votes", force: true do |t|
    t.integer  "division_id",                            null: false
    t.integer  "member_id",                              null: false
    t.string   "vote",        limit: 10
    t.boolean  "teller",                 default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["division_id", "member_id"], name: "division_id_2", unique: true, using: :btree
    t.index ["division_id"], name: "division_id", using: :btree
    t.index ["member_id"], name: "mp_id", using: :btree
    t.index ["teller"], name: "index_votes_on_teller", using: :btree
    t.index ["vote"], name: "index_votes_on_vote", using: :btree
  end

  create_table "watches", force: true do |t|
    t.integer "watchable_id"
    t.string  "watchable_type"
    t.integer "user_id"
  end

  create_table "whips", force: true do |t|
    t.integer  "division_id",                  null: false
    t.string   "party",            limit: 200, null: false
    t.integer  "aye_votes",                    null: false
    t.integer  "aye_tells",                    null: false
    t.integer  "no_votes",                     null: false
    t.integer  "no_tells",                     null: false
    t.integer  "both_votes",                   null: false
    t.integer  "abstention_votes",             null: false
    t.integer  "possible_votes",               null: false
    t.string   "whip_guess",       limit: 10,  null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["division_id", "party"], name: "division_id", unique: true, using: :btree
  end

  create_table "wiki_motions", force: true do |t|
    t.text     "text_body",   null: false
    t.integer  "user_id",     null: false
    t.integer  "division_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["division_id"], name: "index_wiki_motions_on_division_id", using: :btree
  end

end
