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

ActiveRecord::Schema[8.1].define(version: 2026_08_23_000000) do
  create_table "allocations", force: :cascade do |t|
    t.decimal "amount", precision: 19, scale: 4, null: false
    t.integer "budget_id", null: false
    t.string "colour", default: "green", null: false
    t.datetime "created_at", null: false
    t.string "currency_code", limit: 3, null: false
    t.datetime "deleted_at"
    t.string "icon", default: "wallet", null: false
    t.string "name", null: false
    t.boolean "planned", default: true, null: false
    t.decimal "rate", precision: 24, scale: 12, default: "1.0", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id"], name: "index_allocations_on_budget_id"
    t.index ["budget_id"], name: "index_allocations_on_budget_id_and_currency_code"
    t.index ["deleted_at"], name: "index_allocations_on_deleted_at"
    t.check_constraint "amount >= 0", name: "allocations_amount_non_negative"
    t.check_constraint "rate > 0", name: "allocations_rate_positive"
  end

  create_table "auth_codes", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.datetime "expires_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_auth_codes_on_code", unique: true
    t.index ["email_address"], name: "index_auth_codes_on_email_address"
    t.index ["expires_at"], name: "index_auth_codes_on_expires_at"
  end

  create_table "budgets", force: :cascade do |t|
    t.string "base_currency_code", limit: 3, null: false
    t.datetime "created_at", null: false
    t.date "period_from", null: false
    t.date "period_to", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_budgets_on_user_id"
  end

  create_table "expenses", force: :cascade do |t|
    t.integer "allocation_id"
    t.decimal "amount", precision: 19, scale: 4, null: false
    t.integer "budget_id", null: false
    t.datetime "created_at", null: false
    t.string "currency_code", limit: 3, null: false
    t.string "note", limit: 200
    t.date "occurred_on", null: false
    t.decimal "rate", precision: 24, scale: 12, default: "1.0", null: false
    t.integer "source_id", null: false
    t.datetime "updated_at", null: false
    t.index ["allocation_id"], name: "index_expenses_on_allocation_id"
    t.index ["budget_id", "currency_code"], name: "index_expenses_on_budget_id_and_currency_code"
    t.index ["budget_id", "occurred_on"], name: "index_expenses_on_budget_id_and_occurred_on"
    t.index ["budget_id"], name: "index_expenses_on_budget_id"
    t.index ["source_id", "occurred_on"], name: "index_expenses_on_source_id_and_occurred_on"
    t.index ["source_id"], name: "index_expenses_on_source_id"
    t.check_constraint "amount > 0", name: "expenses_amount_positive"
    t.check_constraint "rate > 0", name: "expenses_rate_positive"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sources", force: :cascade do |t|
    t.decimal "amount", precision: 19, scale: 4, null: false
    t.integer "budget_id", null: false
    t.string "colour", default: "green", null: false
    t.datetime "created_at", null: false
    t.string "currency_code", limit: 3, null: false
    t.datetime "deleted_at"
    t.string "icon", default: "wallet", null: false
    t.string "name", null: false
    t.decimal "rate", precision: 24, scale: 12, default: "1.0", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id", "currency_code"], name: "index_sources_on_budget_id_and_currency_code"
    t.index ["budget_id"], name: "index_sources_on_budget_id"
    t.index ["deleted_at"], name: "index_sources_on_deleted_at"
    t.check_constraint "amount >= 0", name: "sources_amount_non_negative"
    t.check_constraint "rate > 0", name: "sources_rate_positive"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "allocations", "budgets"
  add_foreign_key "budgets", "users"
  add_foreign_key "expenses", "allocations"
  add_foreign_key "expenses", "budgets"
  add_foreign_key "expenses", "sources"
  add_foreign_key "sessions", "users"
  add_foreign_key "sources", "budgets"
end
