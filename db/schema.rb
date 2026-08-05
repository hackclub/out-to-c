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

ActiveRecord::Schema[8.1].define(version: 2026_08_05_153605) do
  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hca_token"
    t.string "name"
    t.string "pfp"
    t.string "token"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.integer "voyage"
  end

  create_table "voyages", force: :cascade do |t|
    t.string "cargo"
    t.datetime "created_at", null: false
    t.string "desc"
    t.string "hackatime"
    t.float "hours"
    t.integer "last_island"
    t.string "name"
    t.string "repo"
    t.string "reviewer_note"
    t.integer "ship_status"
    t.integer "total_seconds"
    t.datetime "updated_at", null: false
  end
end
