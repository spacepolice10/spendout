class AddRateToCurrencies < ActiveRecord::Migration[8.1]
  def up
    add_column :currencies, :rate, :decimal, precision: 24, scale: 12

    execute <<~SQL.squish
      UPDATE currencies
      SET rate = 1
      WHERE alphabetic_code = (
        SELECT sources.currency_code
        FROM sources
        WHERE sources.budget_id = currencies.budget_id
        ORDER BY sources.created_at ASC, sources.id ASC
        LIMIT 1
      )
    SQL

    currencies_without_rates = select_all(<<~SQL.squish)
      SELECT currencies.id, currencies.budget_id, currencies.alphabetic_code
      FROM currencies
      WHERE currencies.rate IS NULL
      ORDER BY currencies.budget_id, currencies.alphabetic_code
    SQL

    if currencies_without_rates.any?
      details = currencies_without_rates.map do |currency|
        "id=#{currency.fetch("id")} budget_id=#{currency.fetch("budget_id")} code=#{currency.fetch("alphabetic_code")}"
      end.join(", ")

      raise ActiveRecord::MigrationError,
        "Manual rates are required for existing non-base currencies: #{details}"
    end

    change_column_null :currencies, :rate, false
    add_check_constraint :currencies, "rate > 0", name: "currencies_rate_positive"
  end

  def down
    remove_check_constraint :currencies, name: "currencies_rate_positive"
    remove_column :currencies, :rate
  end
end
