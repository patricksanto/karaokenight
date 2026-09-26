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

ActiveRecord::Schema[8.0].define(version: 2026_09_26_070936) do
  create_table "participants", force: :cascade do |t|
    t.integer "room_id", null: false
    t.string "nickname", null: false
    t.string "emoji", default: "🎤", null: false
    t.string "session_token_digest", null: false
    t.boolean "available", null: false
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["room_id", "nickname"], name: "index_participants_on_room_id_and_nickname", unique: true
    t.index ["room_id"], name: "index_participants_on_room_id"
  end

  create_table "performance_singers", force: :cascade do |t|
    t.integer "performance_id", null: false
    t.integer "participant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_id"], name: "index_performance_singers_on_participant_id"
    t.index ["performance_id", "participant_id"], name: "idx_performance_singers_unique", unique: true
    t.index ["performance_id"], name: "index_performance_singers_on_performance_id"
  end

  create_table "performance_voters", force: :cascade do |t|
    t.integer "performance_id", null: false
    t.integer "participant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_id"], name: "index_performance_voters_on_participant_id"
    t.index ["performance_id", "participant_id"], name: "idx_performance_voters_unique", unique: true
    t.index ["performance_id"], name: "index_performance_voters_on_performance_id"
  end

  create_table "performances", force: :cascade do |t|
    t.integer "room_id", null: false
    t.integer "song_request_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "started_at"
    t.datetime "voting_closes_at"
    t.datetime "revealed_at"
    t.decimal "average_score", precision: 4, scale: 1
    t.integer "votes_count", default: 0
    t.text "messages_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["room_id", "status"], name: "index_performances_on_room_id_and_status"
    t.index ["room_id"], name: "index_performances_on_room_id"
    t.index ["song_request_id"], name: "index_performances_on_song_request_id"
  end

  create_table "reactions", force: :cascade do |t|
    t.integer "performance_id", null: false
    t.integer "participant_id", null: false
    t.string "kind", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_id"], name: "index_reactions_on_participant_id"
    t.index ["performance_id", "kind"], name: "index_reactions_on_performance_id_and_kind"
    t.index ["performance_id"], name: "index_reactions_on_performance_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.string "code", null: false
    t.string "name"
    t.integer "status", default: 0, null: false
    t.string "host_token_digest", null: false
    t.text "settings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_rooms_on_code", unique: true
  end

  create_table "song_request_singers", force: :cascade do |t|
    t.integer "song_request_id", null: false
    t.integer "participant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_id"], name: "index_song_request_singers_on_participant_id"
    t.index ["song_request_id", "participant_id"], name: "idx_song_request_singers_unique", unique: true
    t.index ["song_request_id"], name: "index_song_request_singers_on_song_request_id"
  end

  create_table "song_requests", force: :cascade do |t|
    t.integer "room_id", null: false
    t.integer "participant_id", null: false
    t.string "title", null: false
    t.string "artist", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_id"], name: "index_song_requests_on_participant_id"
    t.index ["room_id", "status"], name: "index_song_requests_on_room_id_and_status"
    t.index ["room_id"], name: "index_song_requests_on_room_id"
  end

  create_table "votes", force: :cascade do |t|
    t.integer "performance_id", null: false
    t.integer "participant_id", null: false
    t.integer "score", null: false
    t.text "message"
    t.datetime "hidden_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_id"], name: "index_votes_on_participant_id"
    t.index ["performance_id", "participant_id"], name: "index_votes_on_performance_id_and_participant_id", unique: true
    t.index ["performance_id"], name: "index_votes_on_performance_id"
  end

  add_foreign_key "participants", "rooms"
  add_foreign_key "performance_singers", "participants"
  add_foreign_key "performance_singers", "performances"
  add_foreign_key "performance_voters", "participants"
  add_foreign_key "performance_voters", "performances"
  add_foreign_key "performances", "rooms"
  add_foreign_key "performances", "song_requests"
  add_foreign_key "reactions", "participants"
  add_foreign_key "reactions", "performances"
  add_foreign_key "song_request_singers", "participants"
  add_foreign_key "song_request_singers", "song_requests"
  add_foreign_key "song_requests", "participants"
  add_foreign_key "song_requests", "rooms"
  add_foreign_key "votes", "participants"
  add_foreign_key "votes", "performances"
end
