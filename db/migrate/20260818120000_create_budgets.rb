class CreateBudgets < ActiveRecord::Migration[8.1]
  def change
    create_table :budgets do |t|
      t.references :user, null: false, foreign_key: true
      t.date :period_from, null: false
      t.date :period_to, null: false

      t.timestamps
    end
  end
end
