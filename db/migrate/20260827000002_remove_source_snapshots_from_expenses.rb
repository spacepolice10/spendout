class RemoveSourceSnapshotsFromExpenses < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :expenses, name: :expenses_rate_positive
    remove_check_constraint :expenses, name: :expenses_source_rate_positive

    remove_column :expenses, :rate
    remove_column :expenses, :source_currency_code
    remove_column :expenses, :source_rate
  end

  def down
    add_column :expenses, :rate, :decimal, precision: 24, scale: 12
    add_column :expenses, :source_currency_code, :string, limit: 3
    add_column :expenses, :source_rate, :decimal, precision: 24, scale: 12

    execute <<~SQL
      UPDATE expenses
      SET source_currency_code = (SELECT currency_code FROM sources WHERE sources.id = expenses.source_id),
          source_rate = (SELECT rate FROM sources WHERE sources.id = expenses.source_id),
          rate = (SELECT rate FROM sources WHERE sources.id = expenses.source_id) * conversion_rate
    SQL

    change_column_null :expenses, :rate, false
    change_column_null :expenses, :source_currency_code, false
    change_column_null :expenses, :source_rate, false
    add_check_constraint :expenses, "rate > 0", name: :expenses_rate_positive
    add_check_constraint :expenses, "source_rate > 0", name: :expenses_source_rate_positive
  end
end
