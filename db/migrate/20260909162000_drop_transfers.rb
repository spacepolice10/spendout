class DropTransfers < ActiveRecord::Migration[8.1]
  def up
    drop_table :transfers
  end

  def down
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
  end
end
