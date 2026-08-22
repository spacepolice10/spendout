class InvertCurrencyRates < ActiveRecord::Migration[8.1]
  TABLES = %i[ sources allocations expenses ].freeze

  def up
    TABLES.each do |table|
      execute "UPDATE #{table} SET rate = 1.0 / rate WHERE rate != 1"
    end
  end

  def down
    TABLES.each do |table|
      execute "UPDATE #{table} SET rate = 1.0 / rate WHERE rate != 1"
    end
  end
end
