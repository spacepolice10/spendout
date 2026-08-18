class CreateCurrencies < ActiveRecord::Migration[8.1]
  def change
    create_table :currencies do |t|
      t.references :budget, null: false, foreign_key: true
      t.string :name, null: false
      t.string :alphabetic_code, null: false, limit: 3
      t.string :numeric_code, null: false, limit: 3
      t.string :symbol, null: false

      t.timestamps
    end

    add_index :currencies, [ :budget_id, :alphabetic_code ], unique: true
  end
end
