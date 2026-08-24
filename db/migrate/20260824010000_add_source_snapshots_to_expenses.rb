class AddSourceSnapshotsToExpenses < ActiveRecord::Migration[8.1]
  def change
    add_column :expenses, :source_amount, :decimal, precision: 19, scale: 4
    add_column :expenses, :source_currency_code, :string, limit: 3
    add_column :expenses, :source_rate, :decimal, precision: 24, scale: 12
    add_column :expenses, :conversion_rate, :decimal, precision: 24, scale: 12

    reversible do |direction|
      direction.up do
        execute <<~SQL
          UPDATE expenses
          SET source_amount = amount,
              source_currency_code = currency_code,
              source_rate = rate,
              conversion_rate = 1
        SQL
      end
    end

    change_column_null :expenses, :source_amount, false
    change_column_null :expenses, :source_currency_code, false
    change_column_null :expenses, :source_rate, false
    change_column_null :expenses, :conversion_rate, false

    add_check_constraint :expenses, "source_amount > 0", name: "expenses_source_amount_positive"
    add_check_constraint :expenses, "source_rate > 0", name: "expenses_source_rate_positive"
    add_check_constraint :expenses, "conversion_rate > 0", name: "expenses_conversion_rate_positive"
  end
end
