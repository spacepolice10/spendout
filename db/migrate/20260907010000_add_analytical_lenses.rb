class AddAnalyticalLenses < ActiveRecord::Migration[8.0]
  def change
    create_table :money_weathers do |t|
      t.integer :forecast_days, null: false, default: 7
      t.timestamps
    end
    add_check_constraint :money_weathers, "forecast_days BETWEEN 1 AND 30", name: "money_weathers_forecast_days_range"

    create_table :tiny_leaks, &:timestamps
    create_table :spree_detectors, &:timestamps
    create_table :payday_gravities, &:timestamps
    create_table :repeat_offenders, &:timestamps

    create_table :parallel_yous do |t|
      t.integer :reduction_percentage, null: false, default: 20
      t.timestamps
    end
    add_check_constraint :parallel_yous, "reduction_percentage BETWEEN 1 AND 100", name: "parallel_yous_reduction_range"

    create_table :weekday_fingerprints, &:timestamps

    create_table :rate_watches do |t|
      t.text :currency_codes, null: false, default: "[]"
      t.timestamps
    end
  end
end
