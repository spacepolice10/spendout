class CreateSources < ActiveRecord::Migration[8.1]
  def change
    create_table :sources do |t|
      t.references :budget, null: false, foreign_key: true
      t.string :currency_code, null: false, limit: 3
      t.string :name, null: false, default: "Main source"
      t.decimal :amount, null: false, precision: 19, scale: 4
      t.string :icon, null: false, default: "wallet"
      t.string :colour, null: false, default: "hotpink"
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :sources, :deleted_at
    add_index :sources, [ :budget_id, :currency_code ]
    add_check_constraint :sources, "amount >= 0", name: "sources_amount_non_negative"
  end
end
