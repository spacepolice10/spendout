class CreateExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :expenses do |t|
      t.references :budget, null: false, foreign_key: true
      t.references :source, null: false, foreign_key: true
      t.references :allocation, null: true, foreign_key: true
      t.string :currency_code, null: false, limit: 3
      t.decimal :amount, null: false, precision: 19, scale: 4
      t.date :occurred_on, null: false
      t.string :note, limit: 200

      t.timestamps
    end

    add_index :expenses, [ :budget_id, :occurred_on ]
    add_index :expenses, [ :source_id, :occurred_on ]
    add_index :expenses, [ :budget_id, :currency_code ]
    add_check_constraint :expenses, "amount > 0", name: "expenses_amount_positive"
  end
end
