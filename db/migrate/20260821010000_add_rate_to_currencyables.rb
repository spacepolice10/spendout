class AddRateToCurrencyables < ActiveRecord::Migration[8.1]
  def change
    add_column :sources, :rate, :decimal, precision: 24, scale: 12, null: false, default: 1
    add_column :allocations, :rate, :decimal, precision: 24, scale: 12, null: false, default: 1
    add_column :expenses, :rate, :decimal, precision: 24, scale: 12, null: false, default: 1

    add_check_constraint :sources, "rate > 0", name: "sources_rate_positive"
    add_check_constraint :allocations, "rate > 0", name: "allocations_rate_positive"
    add_check_constraint :expenses, "rate > 0", name: "expenses_rate_positive"
  end
end
