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

ActiveRecord::Schema[7.2].define(version: 2025_03_10_170743) do
  create_table "follows", id: { type: :string, limit: 36 }, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "follower_id", limit: 36, null: false
    t.string "followed_id", limit: 36, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active", "followed_id"], name: "index_follows_on_active_and_followed_id"
    t.index ["active", "follower_id"], name: "index_follows_on_active_and_follower_id"
    t.index ["follower_id", "followed_id"], name: "index_follows_on_follower_id_and_followed_id", unique: true
  end

  create_table "sleep_records", id: { type: :string, limit: 36 }, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "user_id", null: false
    t.datetime "clocked_in_at", null: false
    t.datetime "clocked_out_at"
    t.integer "duration", default: 0, null: false
    t.string "state", default: "clocked_in", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["state"], name: "index_sleep_records_on_state"
    t.index ["user_id", "clocked_in_at"], name: "index_sleep_records_on_user_id_and_clocked_in_at"
  end

  create_table "users", id: { type: :string, limit: 36 }, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "username", limit: 20, null: false
    t.string "password_digest", null: false
    t.string "name", limit: 30, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["username"], name: "index_users_on_username", unique: true
  end
end
