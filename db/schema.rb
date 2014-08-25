# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20140825021413) do

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
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "division_infos", force: true do |t|
    t.integer "division_id",      null: false
    t.integer "rebellions",       null: false
    t.integer "tells",            null: false
    t.integer "turnout",          null: false
    t.integer "possible_turnout", null: false
    t.integer "aye_majority",     null: false
  end

  add_index "division_infos", ["division_id"], name: "division_id", using: :btree

  create_table "divisions", force: true do |t|
    t.boolean "valid"
    t.date    "division_date",             null: false
    t.integer "division_number",           null: false
    t.string  "house",           limit: 8, null: false
    t.text    "division_name",             null: false
    t.binary  "source_url",                null: false
    t.binary  "debate_url",                null: false
    t.binary  "motion",                    null: false
    t.binary  "notes",                     null: false
    t.text    "clock_time"
    t.text    "source_gid",                null: false
    t.text    "debate_gid",                null: false
  end

  add_index "divisions", ["division_date", "division_number", "house"], name: "division_date_2", unique: true, using: :btree
  add_index "divisions", ["division_date"], name: "division_date", using: :btree
  add_index "divisions", ["division_number"], name: "division_number", using: :btree
  add_index "divisions", ["house"], name: "house", using: :btree

  create_table "electorates", force: true do |t|
    t.string  "name",      limit: 100,                        null: false
    t.boolean "main_name",                                    null: false
    t.date    "from_date",             default: '1000-01-01', null: false
    t.date    "to_date",               default: '9999-12-31', null: false
    t.string  "house",     limit: 8,   default: "commons",    null: false
  end

  add_index "electorates", ["from_date"], name: "from_date", using: :btree
  add_index "electorates", ["id", "name"], name: "cons_id", using: :btree
  add_index "electorates", ["name"], name: "name", using: :btree
  add_index "electorates", ["to_date"], name: "to_date", using: :btree

  create_table "member_distances", force: true do |t|
    t.integer "member1_id",              null: false
    t.integer "member2_id",              null: false
    t.integer "nvotessame"
    t.integer "nvotesdiffer"
    t.integer "nvotesabsent"
    t.float   "distance_a",   limit: 24
    t.float   "distance_b",   limit: 24
  end

  add_index "member_distances", ["member1_id", "member2_id"], name: "mp_id1_2", unique: true, using: :btree
  add_index "member_distances", ["member1_id"], name: "mp_id1", using: :btree
  add_index "member_distances", ["member2_id"], name: "mp_id2", using: :btree

  create_table "member_infos", force: true do |t|
    t.integer "member_id",      null: false
    t.integer "rebellions",     null: false
    t.integer "tells",          null: false
    t.integer "votes_attended", null: false
    t.integer "votes_possible", null: false
    t.integer "aye_majority",   null: false
  end

  add_index "member_infos", ["member_id"], name: "mp_id", using: :btree

  create_table "members", force: true do |t|
    t.string  "gid",            limit: 100,                        null: false
    t.text    "source_gid",                                        null: false
    t.string  "first_name",     limit: 100,                        null: false
    t.string  "last_name",      limit: 100,                        null: false
    t.string  "title",          limit: 50,                         null: false
    t.string  "constituency",   limit: 100,                        null: false
    t.string  "party",          limit: 100,                        null: false
    t.string  "house",          limit: 8,                          null: false
    t.date    "entered_house",              default: '1000-01-01', null: false
    t.date    "left_house",                 default: '9999-12-31', null: false
    t.string  "entered_reason", limit: 16,  default: "unknown",    null: false
    t.string  "left_reason",    limit: 28,  default: "unknown",    null: false
    t.integer "person"
  end

  add_index "members", ["entered_house"], name: "entered_house", using: :btree
  add_index "members", ["gid"], name: "gid", using: :btree
  add_index "members", ["house"], name: "house", using: :btree
  add_index "members", ["left_house"], name: "left_house", using: :btree
  add_index "members", ["party"], name: "party", using: :btree
  add_index "members", ["person"], name: "person", using: :btree
  add_index "members", ["title", "first_name", "last_name", "constituency", "entered_house", "left_house", "house"], name: "title", unique: true, using: :btree

  create_table "offices", force: true do |t|
    t.string  "dept",           limit: 100,                        null: false
    t.string  "position",       limit: 100,                        null: false
    t.string  "responsibility", limit: 100,                        null: false
    t.date    "from_date",                  default: '1000-01-01', null: false
    t.date    "to_date",                    default: '9999-12-31', null: false
    t.integer "person"
  end

  add_index "offices", ["person"], name: "person", using: :btree

  create_table "policies", force: true do |t|
    t.string  "name",        limit: 100, null: false
    t.integer "user_id",                 null: false
    t.binary  "description",             null: false
    t.integer "private",     limit: 1,   null: false
  end

  add_index "policies", ["id", "name", "user_id"], name: "dream_id", unique: true, using: :btree
  add_index "policies", ["user_id"], name: "user_id", using: :btree

  create_table "policy_divisions", force: true do |t|
    t.date    "division_date",              null: false
    t.integer "division_number",            null: false
    t.string  "house",           limit: 8,  null: false
    t.integer "policy_id",                  null: false
    t.string  "vote",            limit: 10, null: false
  end

  add_index "policy_divisions", ["division_date", "division_number", "house", "policy_id"], name: "division_date_2", unique: true, using: :btree
  add_index "policy_divisions", ["division_date"], name: "division_date", using: :btree
  add_index "policy_divisions", ["division_number"], name: "division_number", using: :btree
  add_index "policy_divisions", ["policy_id"], name: "dream_id", using: :btree

  create_table "policy_member_distances", force: true do |t|
    t.integer "policy_id",                     null: false
    t.integer "person",                        null: false
    t.integer "nvotessame"
    t.integer "nvotessamestrong"
    t.integer "nvotesdiffer"
    t.integer "nvotesdifferstrong"
    t.integer "nvotesabsent"
    t.integer "nvotesabsentstrong"
    t.float   "distance_a",         limit: 24
    t.float   "distance_b",         limit: 24
  end

  add_index "policy_member_distances", ["person"], name: "person", using: :btree
  add_index "policy_member_distances", ["policy_id", "person"], name: "dream_id_2", unique: true, using: :btree
  add_index "policy_member_distances", ["policy_id"], name: "dream_id", using: :btree

  create_table "pw_cache_divwiki", force: true do |t|
    t.date    "division_date",             null: false
    t.integer "division_number",           null: false
    t.string  "house",           limit: 8, null: false
    t.integer "wiki_id",                   null: false
  end

  add_index "pw_cache_divwiki", ["division_date", "division_number", "house"], name: "division_date", unique: true, using: :btree

  create_table "users", force: true do |t|
    t.text     "user_name"
    t.text     "real_name"
    t.text     "email"
    t.text     "legacy_password"
    t.text     "remote_addr"
    t.text     "confirm_hash"
    t.text     "confirm_return_url"
    t.integer  "is_confirmed",           default: 0,  null: false
    t.datetime "reg_date"
    t.integer  "active_policy_id"
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
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "vote_sortorders", force: true do |t|
    t.string  "vote",     limit: 10, null: false
    t.integer "position",            null: false
  end

  create_table "votes", force: true do |t|
    t.integer "division_id",            null: false
    t.integer "member_id",              null: false
    t.string  "vote",        limit: 10, null: false
  end

  add_index "votes", ["division_id", "member_id", "vote"], name: "division_id_2", unique: true, using: :btree
  add_index "votes", ["division_id"], name: "division_id", using: :btree
  add_index "votes", ["member_id"], name: "mp_id", using: :btree
  add_index "votes", ["vote"], name: "vote", using: :btree

  create_table "whips", force: true do |t|
    t.integer "division_id",                  null: false
    t.string  "party",            limit: 200, null: false
    t.integer "aye_votes",                    null: false
    t.integer "aye_tells",                    null: false
    t.integer "no_votes",                     null: false
    t.integer "no_tells",                     null: false
    t.integer "both_votes",                   null: false
    t.integer "abstention_votes",             null: false
    t.integer "possible_votes",               null: false
    t.string  "whip_guess",       limit: 10,  null: false
  end

  add_index "whips", ["division_id", "party"], name: "division_id", unique: true, using: :btree

  create_table "wiki_motions", primary_key: "wiki_id", force: true do |t|
    t.date     "division_date",             null: false
    t.integer  "division_number",           null: false
    t.string   "house",           limit: 8, null: false
    t.text     "text_body",                 null: false
    t.integer  "user_id",                   null: false
    t.datetime "edit_date"
  end

  add_index "wiki_motions", ["division_date", "division_number", "house"], name: "division_date", using: :btree

end
