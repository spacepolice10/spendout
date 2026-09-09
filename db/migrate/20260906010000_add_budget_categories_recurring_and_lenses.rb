class AddBudgetCategoriesRecurringAndLenses < ActiveRecord::Migration[8.1]
  def up
    create_table :categories do |t|
      t.references :budget, null: false, foreign_key: true
      t.string :name, null: false
      t.string :icon, null: false, default: "wallet"
      t.string :colour, null: false, default: "green"
      t.datetime :deleted_at
      t.timestamps
    end
    add_index :categories, [ :budget_id, :name ]
    add_index :categories, :deleted_at

    add_reference :allocations, :category, foreign_key: true
    add_reference :expenses, :category, foreign_key: true

    category_class = Class.new(ActiveRecord::Base) { self.table_name = "categories" }
    allocation_class = Class.new(ActiveRecord::Base) { self.table_name = "allocations" }
    expense_class = Class.new(ActiveRecord::Base) { self.table_name = "expenses" }

    allocation_class.reset_column_information
    expense_class.reset_column_information

    allocation_class.order(:id).find_each do |allocation|
      category = category_class.create!(
        budget_id: allocation.budget_id,
        name: allocation.name,
        icon: allocation.icon,
        colour: allocation.colour,
        deleted_at: allocation.deleted_at
      )
      allocation.update_columns(category_id: category.id)
    end

    expense_class.where.not(allocation_id: nil).find_each do |expense|
      category_id = allocation_class.where(id: expense.allocation_id).pick(:category_id)
      expense.update_columns(category_id:) if category_id
    end

    expense_class.where(category_id: nil).pluck(:budget_id).uniq.each do |budget_id|
      category = category_class.create!(budget_id:, name: "Needs category", icon: "category", colour: "green")
      expense_class.where(budget_id:, category_id: nil).update_all(category_id: category.id)
    end

    allocation_class.where(planned: false).delete_all

    change_column_null :allocations, :category_id, false
    change_column_null :expenses, :category_id, false
    add_index :allocations, [ :budget_id, :category_id ], unique: true

    remove_reference :expenses, :allocation, foreign_key: true
    remove_column :allocations, :name, :string
    remove_column :allocations, :icon, :string
    remove_column :allocations, :colour, :string
    remove_column :allocations, :planned, :boolean

    create_table :incomes do |t|
      t.references :budget, null: false, foreign_key: true
      t.references :source, null: false, foreign_key: true
      t.string :source_name, null: false
      t.decimal :amount, precision: 19, scale: 4, null: false
      t.string :currency_code, limit: 3, null: false
      t.decimal :source_amount, precision: 19, scale: 4, null: false
      t.decimal :conversion_rate, precision: 24, scale: 12, null: false
      t.string :note, limit: 200
      t.date :occurred_on, null: false
      t.timestamps
    end
    add_check_constraint :incomes, "amount > 0", name: :incomes_amount_positive
    add_check_constraint :incomes, "source_amount > 0", name: :incomes_source_amount_positive
    add_check_constraint :incomes, "conversion_rate > 0", name: :incomes_conversion_rate_positive
    add_index :incomes, [ :budget_id, :occurred_on ]

    create_table :transfers do |t|
      t.references :budget, null: false, foreign_key: true
      t.references :sender_source, null: false, foreign_key: { to_table: :sources }
      t.references :receiver_source, null: false, foreign_key: { to_table: :sources }
      t.decimal :amount, precision: 19, scale: 4, null: false
      t.date :occurred_on, null: false
      t.string :note, limit: 200
      t.timestamps
    end
    add_check_constraint :transfers, "amount > 0", name: :transfers_amount_positive
    add_check_constraint :transfers, "sender_source_id <> receiver_source_id", name: :transfers_distinct_sources
    add_index :transfers, [ :budget_id, :occurred_on ]

    create_table :recurring_items do |t|
      t.references :budget, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :amount, precision: 19, scale: 4, null: false
      t.string :currency_code, limit: 3, null: false
      t.date :occurs_on, null: false
      t.integer :occurrence_period_in_days, null: false
      t.string :note, limit: 200
      t.datetime :ended_at
      t.timestamps
    end
    add_check_constraint :recurring_items, "amount > 0", name: :recurring_items_amount_positive
    add_check_constraint :recurring_items, "occurrence_period_in_days > 0", name: :recurring_items_period_positive
    add_index :recurring_items, [ :budget_id, :occurs_on ]

    create_table :recurring_occurrences do |t|
      t.references :recurring_item, null: false, foreign_key: true
      t.references :expense, null: false, foreign_key: true, index: { unique: true }
      t.date :due_on, null: false
      t.timestamps
    end
    add_index :recurring_occurrences, [ :recurring_item_id, :due_on ], unique: true

    create_table :source_holders do |t|
      t.timestamps
    end

    create_table :plan_overviews do |t|
      t.timestamps
    end

    create_table :rollovers do |t|
      t.integer :limit_source, null: false, default: 1
      t.decimal :amount, precision: 19, scale: 4, null: false, default: 0
      t.decimal :opening_amount, precision: 19, scale: 4
      t.string :currency_code, limit: 3, null: false
      t.decimal :rate, precision: 24, scale: 12, null: false, default: 1
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.timestamps
    end
    add_check_constraint :rollovers, "amount >= 0", name: :rollovers_amount_non_negative
    add_check_constraint :rollovers, "rate > 0", name: :rollovers_rate_positive
    add_check_constraint :rollovers, "ends_on >= starts_on", name: :rollovers_period_valid

    create_table :most_expensive_categories do |t|
      t.date :starts_on, null: false
      t.timestamps
    end

    create_table :recent_expenses do |t|
      t.integer :preview_limit, null: false, default: 5
      t.timestamps
    end
    add_check_constraint :recent_expenses, "preview_limit >= 1 AND preview_limit <= 20", name: :recent_expenses_preview_limit_range

    create_table :upcoming_recurring_items do |t|
      t.timestamps
    end

    create_table :lenses do |t|
      t.references :budget, null: false, foreign_key: true
      t.references :lensable, polymorphic: true, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :lenses, [ :budget_id, :lensable_type ]
    add_index :lenses, [ :budget_id, :lensable_type ], unique: true,
      where: "lensable_type IN ('SourceHolder', 'PlanOverview', 'Rollover')",
      name: :index_one_singleton_lens_type_per_budget

    source_holder_class = Class.new(ActiveRecord::Base) { self.table_name = "source_holders" }
    plan_overview_class = Class.new(ActiveRecord::Base) { self.table_name = "plan_overviews" }
    lens_class = Class.new(ActiveRecord::Base) { self.table_name = "lenses" }

    select_values("SELECT id FROM budgets").each do |budget_id|
      holder = source_holder_class.create!
      plan = plan_overview_class.create!
      lens_class.create!(budget_id:, lensable_type: "SourceHolder", lensable_id: holder.id, position: 0)
      lens_class.create!(budget_id:, lensable_type: "PlanOverview", lensable_id: plan.id, position: 1)
    end
  end

  def down
    drop_table :lenses
    drop_table :upcoming_recurring_items
    drop_table :recent_expenses
    drop_table :most_expensive_categories
    drop_table :rollovers
    drop_table :plan_overviews
    drop_table :source_holders
    drop_table :recurring_occurrences
    drop_table :recurring_items
    drop_table :transfers
    drop_table :incomes

    add_column :allocations, :name, :string
    add_column :allocations, :icon, :string, default: "wallet", null: false
    add_column :allocations, :colour, :string, default: "green", null: false
    add_column :allocations, :planned, :boolean, default: true, null: false
    add_reference :expenses, :allocation, foreign_key: true
    remove_index :allocations, [ :budget_id, :category_id ]
    remove_reference :expenses, :category, foreign_key: true
    remove_reference :allocations, :category, foreign_key: true
    drop_table :categories
  end
end
