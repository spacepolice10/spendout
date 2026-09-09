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

ActiveRecord::Schema[8.1].define(version: 2026_09_09_162000) do
  create_table "allocations", force: :cascade do |t|
    t.decimal "amount", precision: 19, scale: 4, null: false
    t.integer "budget_id", null: false
    t.integer "category_id", null: false
    t.datetime "created_at", null: false
    t.string "currency_code", limit: 3, null: false
    t.datetime "deleted_at"
    t.datetime "finished_at"
    t.decimal "rate", precision: 24, scale: 12, default: "1.0", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id", "category_id"], name: "index_allocations_on_budget_id_and_category_id", unique: true
    t.index ["budget_id", "currency_code"], name: "index_allocations_on_budget_id_and_currency_code"
    t.index ["budget_id"], name: "index_allocations_on_budget_id"
    t.index ["category_id"], name: "index_allocations_on_category_id"
    t.index ["deleted_at"], name: "index_allocations_on_deleted_at"
    t.index ["finished_at"], name: "index_allocations_on_finished_at"
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

  create_table "categories", force: :cascade do |t|
    t.integer "budget_id", null: false
    t.string "colour", default: "green", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "icon", default: "wallet", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id", "name"], name: "index_categories_on_budget_id_and_name"
    t.index ["budget_id"], name: "index_categories_on_budget_id"
    t.index ["deleted_at"], name: "index_categories_on_deleted_at"
  end

  create_table "exchanges", force: :cascade do |t|
    t.integer "budget_id", null: false
    t.datetime "created_at", null: false
    t.decimal "rate", precision: 24, scale: 12, null: false
    t.decimal "receiver_amount", precision: 19, scale: 4, null: false
    t.integer "receiver_source_id", null: false
    t.decimal "sender_amount", precision: 19, scale: 4, null: false
    t.integer "sender_source_id", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id", "created_at"], name: "index_exchanges_on_budget_id_and_created_at"
    t.index ["budget_id"], name: "index_exchanges_on_budget_id"
    t.index ["receiver_source_id"], name: "index_exchanges_on_receiver_source_id", unique: true
    t.index ["sender_source_id"], name: "index_exchanges_on_sender_source_id"
    t.check_constraint "rate > 0", name: "exchanges_rate_positive"
    t.check_constraint "receiver_amount > 0", name: "exchanges_receiver_amount_positive"
    t.check_constraint "sender_amount > 0", name: "exchanges_sender_amount_positive"
  end

  create_table "expenses", force: :cascade do |t|
    t.decimal "amount", precision: 19, scale: 4, null: false
    t.integer "budget_id", null: false
    t.integer "category_id", null: false
    t.decimal "conversion_rate", precision: 24, scale: 12, null: false
    t.datetime "created_at", null: false
    t.string "currency_code", limit: 3, null: false
    t.string "note", limit: 200
    t.date "occurred_on", null: false
    t.decimal "source_amount", precision: 19, scale: 4, null: false
    t.integer "source_id", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id", "currency_code"], name: "index_expenses_on_budget_id_and_currency_code"
    t.index ["budget_id", "occurred_on"], name: "index_expenses_on_budget_id_and_occurred_on"
    t.index ["budget_id"], name: "index_expenses_on_budget_id"
    t.index ["category_id"], name: "index_expenses_on_category_id"
    t.index ["source_id", "occurred_on"], name: "index_expenses_on_source_id_and_occurred_on"
    t.index ["source_id"], name: "index_expenses_on_source_id"
    t.check_constraint "amount > 0", name: "expenses_amount_positive"
    t.check_constraint "conversion_rate > 0", name: "expenses_conversion_rate_positive"
    t.check_constraint "source_amount > 0", name: "expenses_source_amount_positive"
  end

  create_table "features", force: :cascade do |t|
    t.integer "budget_id", null: false
    t.datetime "created_at", null: false
    t.boolean "favorite", default: false, null: false
    t.string "feature_type", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id", "feature_type"], name: "index_features_on_budget_id_and_feature_type", unique: true
    t.index ["budget_id"], name: "index_features_on_budget_id"
    t.check_constraint "feature_type IN ('new_expense', 'new_income', 'new_source', 'new_allocation', 'lens_laboratory')", name: "features_known_type"
  end

  create_table "incomes", force: :cascade do |t|
    t.decimal "amount", precision: 19, scale: 4, null: false
    t.integer "budget_id", null: false
    t.decimal "conversion_rate", precision: 24, scale: 12, null: false
    t.datetime "created_at", null: false
    t.string "currency_code", limit: 3, null: false
    t.string "note", limit: 200
    t.date "occurred_on", null: false
    t.decimal "source_amount", precision: 19, scale: 4, null: false
    t.integer "source_id", null: false
    t.string "source_name", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id", "occurred_on"], name: "index_incomes_on_budget_id_and_occurred_on"
    t.index ["budget_id"], name: "index_incomes_on_budget_id"
    t.index ["source_id"], name: "index_incomes_on_source_id"
    t.check_constraint "amount > 0", name: "incomes_amount_positive"
    t.check_constraint "conversion_rate > 0", name: "incomes_conversion_rate_positive"
    t.check_constraint "source_amount > 0", name: "incomes_source_amount_positive"
  end

  create_table "lenses", force: :cascade do |t|
    t.integer "budget_id", null: false
    t.datetime "created_at", null: false
    t.integer "lensable_id", null: false
    t.string "lensable_type", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id", "lensable_type"], name: "index_lenses_on_budget_id_and_lensable_type"
    t.index ["budget_id", "lensable_type"], name: "index_one_singleton_lens_type_per_budget", unique: true, where: "lensable_type IN ('SourceHolder', 'PlanOverview', 'Rollover', 'RateInfo')"
    t.index ["budget_id", "position"], name: "index_lenses_on_budget_id_and_position"
    t.index ["budget_id"], name: "index_lenses_on_budget_id"
    t.index ["lensable_type", "lensable_id"], name: "index_lenses_on_lensable"
  end

  create_table "most_expensive_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "starts_on", null: false
    t.datetime "updated_at", null: false
  end

  create_table "plan_overviews", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rate_infos", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "currency_codes", default: "[]", null: false
    t.datetime "updated_at", null: false
  end

  create_table "records", force: :cascade do |t|
    t.integer "budget_id", null: false
    t.datetime "created_at", null: false
    t.date "occurred_on", null: false
    t.integer "recordable_id", null: false
    t.string "recordable_type", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id", "occurred_on", "created_at", "id"], name: "index_records_on_budget_timeline"
    t.index ["budget_id"], name: "index_records_on_budget_id"
    t.index ["recordable_type", "recordable_id"], name: "index_records_on_recordable", unique: true
  end

  create_table "recurrences", force: :cascade do |t|
    t.decimal "amount", precision: 19, scale: 4, null: false
    t.integer "budget_id", null: false
    t.integer "category_id", null: false
    t.datetime "created_at", null: false
    t.string "currency_code", limit: 3, null: false
    t.datetime "ended_at"
    t.string "name", null: false
    t.string "note", limit: 200
    t.integer "occurrence_period_in_days", null: false
    t.date "occurs_on", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id", "occurs_on"], name: "index_recurrences_on_budget_id_and_occurs_on"
    t.index ["budget_id"], name: "index_recurrences_on_budget_id"
    t.index ["category_id"], name: "index_recurrences_on_category_id"
    t.check_constraint "amount > 0", name: "recurring_items_amount_positive"
    t.check_constraint "occurrence_period_in_days > 0", name: "recurring_items_period_positive"
  end

  create_table "recurring_occurrences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "due_on", null: false
    t.integer "expense_id", null: false
    t.integer "recurrence_id", null: false
    t.datetime "updated_at", null: false
    t.index ["expense_id"], name: "index_recurring_occurrences_on_expense_id", unique: true
    t.index ["recurrence_id", "due_on"], name: "index_recurring_occurrences_on_recurrence_id_and_due_on", unique: true
    t.index ["recurrence_id"], name: "index_recurring_occurrences_on_recurrence_id"
  end

  create_table "rollovers", force: :cascade do |t|
    t.decimal "amount", precision: 19, scale: 4, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.string "currency_code", limit: 3, null: false
    t.date "ends_on", null: false
    t.integer "limit_source", default: 1, null: false
    t.decimal "opening_amount", precision: 19, scale: 4
    t.decimal "rate", precision: 24, scale: 12, default: "1.0", null: false
    t.date "starts_on", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "amount >= 0", name: "rollovers_amount_non_negative"
    t.check_constraint "ends_on >= starts_on", name: "rollovers_period_valid"
    t.check_constraint "rate > 0", name: "rollovers_rate_positive"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "source_holders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sources", force: :cascade do |t|
    t.decimal "amount", precision: 19, scale: 4, null: false
    t.integer "budget_id", null: false
    t.string "colour", default: "green", null: false
    t.datetime "created_at", null: false
    t.string "currency_code", limit: 3, null: false
    t.datetime "deleted_at"
    t.integer "design", default: 0, null: false
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

  create_table "upcoming_recurrences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "allocations", "budgets"
  add_foreign_key "allocations", "categories"
  add_foreign_key "budgets", "users"
  add_foreign_key "categories", "budgets"
  add_foreign_key "exchanges", "budgets"
  add_foreign_key "exchanges", "sources", column: "receiver_source_id"
  add_foreign_key "exchanges", "sources", column: "sender_source_id"
  add_foreign_key "expenses", "budgets"
  add_foreign_key "expenses", "categories"
  add_foreign_key "expenses", "sources"
  add_foreign_key "features", "budgets"
  add_foreign_key "incomes", "budgets"
  add_foreign_key "incomes", "sources"
  add_foreign_key "lenses", "budgets"
  add_foreign_key "records", "budgets"
  add_foreign_key "recurrences", "budgets"
  add_foreign_key "recurrences", "categories"
  add_foreign_key "recurring_occurrences", "expenses"
  add_foreign_key "recurring_occurrences", "recurrences"
  add_foreign_key "sessions", "users"
  add_foreign_key "sources", "budgets"
end
