class CreateExchanges < ActiveRecord::Migration[8.1]
  def change
    create_table :exchanges do |t|
      t.references :budget, null: false, foreign_key: true
      t.references :parent_source, null: false, foreign_key: { to_table: :sources }
      t.references :child_source, null: false, foreign_key: { to_table: :sources }, index: { unique: true }
      t.decimal :parent_amount, precision: 19, scale: 4, null: false
      t.decimal :child_amount, precision: 19, scale: 4, null: false
      t.decimal :rate, precision: 24, scale: 12, null: false
      t.string :parent_currency_code, limit: 3, null: false
      t.string :child_currency_code, limit: 3, null: false

      t.timestamps
    end

    add_check_constraint :exchanges, "parent_amount > 0", name: "exchanges_parent_amount_positive"
    add_check_constraint :exchanges, "child_amount > 0", name: "exchanges_child_amount_positive"
    add_check_constraint :exchanges, "rate > 0", name: "exchanges_rate_positive"
    add_index :exchanges, [ :budget_id, :created_at ]
  end
end
