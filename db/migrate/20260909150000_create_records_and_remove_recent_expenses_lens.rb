class CreateRecordsAndRemoveRecentExpensesLens < ActiveRecord::Migration[8.1]
  def up
    create_table :records do |t|
      t.references :budget, null: false, foreign_key: true
      t.string :recordable_type, null: false
      t.integer :recordable_id, null: false
      t.date :occurred_on, null: false
      t.timestamps
    end
    add_index :records, [ :recordable_type, :recordable_id ], unique: true, name: "index_records_on_recordable"
    add_index :records, [ :budget_id, :occurred_on, :created_at, :id ], name: "index_records_on_budget_timeline"

    execute <<~SQL.squish
      INSERT INTO records (budget_id, recordable_type, recordable_id, occurred_on, created_at, updated_at)
      SELECT budget_id, 'Expense', id, occurred_on, created_at, updated_at FROM expenses
      UNION ALL
      SELECT budget_id, 'Income', id, occurred_on, created_at, updated_at FROM incomes
    SQL

    execute "DELETE FROM lenses WHERE lensable_type = 'RecentExpenses'"
    drop_table :recent_expenses
  end

  def down
    create_table :recent_expenses do |t|
      t.integer :preview_limit, null: false, default: 5
      t.timestamps
    end
    add_check_constraint :recent_expenses, "preview_limit >= 1 AND preview_limit <= 20", name: :recent_expenses_preview_limit_range

    drop_table :records
  end
end
