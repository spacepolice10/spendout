class RemoveRetiredAnalyticalLenses < ActiveRecord::Migration[8.1]
  TYPES = %w[
    MoneyWeather
    TinyLeaks
    SpreeDetector
    PaydayGravity
    RepeatOffenders
    ParallelYou
    WeekdayFingerprint
  ].freeze

  TABLES = %i[
    money_weathers
    tiny_leaks
    spree_detectors
    payday_gravities
    repeat_offenders
    parallel_yous
    weekday_fingerprints
  ].freeze

  def up
    execute <<~SQL.squish
      DELETE FROM lenses
      WHERE lensable_type IN (#{TYPES.map { |type| connection.quote(type) }.join(", ")})
    SQL

    TABLES.each { |table| drop_table table }
  end

  def down
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
  end
end
