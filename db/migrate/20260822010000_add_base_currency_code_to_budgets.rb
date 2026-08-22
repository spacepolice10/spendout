class AddBaseCurrencyCodeToBudgets < ActiveRecord::Migration[8.1]
  def up
    add_column :budgets, :base_currency_code, :string, limit: 3

    execute <<~SQL
      UPDATE budgets
      SET base_currency_code = (
        SELECT sources.currency_code
        FROM sources
        WHERE sources.budget_id = budgets.id
        ORDER BY sources.created_at ASC, sources.id ASC
        LIMIT 1
      )
    SQL

    change_column_null :budgets, :base_currency_code, false
  end

  def down
    remove_column :budgets, :base_currency_code
  end
end
