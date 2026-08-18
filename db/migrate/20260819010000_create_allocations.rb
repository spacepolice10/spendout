class CreateAllocations < ActiveRecord::Migration[8.1]
  def change
    create_table :allocations do |t|
      t.references :budget, null: false, foreign_key: true
      t.references :source, null: false, foreign_key: true
      t.string :currency_code, null: false, limit: 3
      t.string :name, null: false
      t.decimal :amount, null: false, precision: 19, scale: 4
      t.string :icon, null: false, default: "wallet"
      t.string :colour, null: false, default: "green"
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :allocations, :deleted_at
    add_index :allocations, [ :source_id, :deleted_at ]
    add_index :allocations, [ :budget_id, :currency_code ]
    add_check_constraint :allocations, "amount >= 0", name: "allocations_amount_non_negative"
  end
end
