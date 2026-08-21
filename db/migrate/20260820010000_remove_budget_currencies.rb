class RemoveBudgetCurrencies < ActiveRecord::Migration[8.1]
  def up
    drop_table :currencies
  end

  def down
    create_table :currencies do |t|
      t.references :budget, null: false, foreign_key: true
      t.string :alphabetic_code, null: false, limit: 3
      t.string :numeric_code, null: false, limit: 3
      t.string :name, null: false
      t.string :symbol, null: false
      t.decimal :rate, precision: 24, scale: 12, null: false
      t.timestamps
    end
    add_index :currencies, [ :budget_id, :alphabetic_code ], unique: true
    add_check_constraint :currencies, "rate > 0", name: "currencies_rate_positive"
  end
end
