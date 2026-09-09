require "test_helper"

class LensTest < ActiveSupport::TestCase
  setup { @budget = budgets(:active) }

  test "ensures exactly one source holder and plan overview" do
    assert_difference("Lens.count", 2) { @budget.ensure_builtin_lenses! }
    assert_no_difference("Lens.count") { @budget.ensure_builtin_lenses! }

    assert_equal %w[PlanOverview SourceHolder], @budget.lenses.pluck(:lensable_type).sort
    assert_raises(ActiveRecord::RecordNotDestroyed) { @budget.lenses.find_by!(lensable_type: "SourceHolder").destroy! }
  end

  test "optional lens owns its visual configuration" do
    lensable = UpcomingRecurrences.new
    lens = @budget.lenses.create!(lensable:)

    snapshot = lens.snapshot(on: Date.new(2026, 8, 20))
    assert_equal [], snapshot.items

    assert_difference([ "Lens.count", "UpcomingRecurrences.count" ], -1) { lens.destroy! }
  end

  test "new lenses append and lenses can move within their budget" do
    @budget.ensure_builtin_lenses!
    upcoming = @budget.lenses.create!(lensable: UpcomingRecurrences.new)

    assert_equal [ 0, 1, 2 ], @budget.lenses.positioned.pluck(:position)
    assert_equal upcoming, @budget.lenses.positioned.last

    assert upcoming.move!("up")
    assert_equal [ "SourceHolder", "UpcomingRecurrences", "PlanOverview" ], @budget.lenses.positioned.pluck(:lensable_type)
    assert upcoming.move!("up")
    assert_not upcoming.move!("up")
    assert_equal upcoming, @budget.lenses.positioned.first
  end

  test "removing a lens closes its position gap" do
    @budget.ensure_builtin_lenses!
    upcoming = @budget.lenses.create!(lensable: UpcomingRecurrences.new)
    @budget.lenses.create!(lensable: MostExpensiveCategories.new(starts_on: @budget.period_from))

    upcoming.destroy!

    assert_equal [ 0, 1, 2 ], @budget.lenses.positioned.pluck(:position)
  end

  test "rollover is unique per budget" do
    attributes = {
      limit_source: :manual, amount: 300, currency_code: "USD", rate: 1,
      starts_on: @budget.period_from, ends_on: @budget.period_to
    }
    @budget.lenses.create!(lensable: Rollover.new(attributes))
    duplicate = @budget.lenses.new(lensable: Rollover.new(attributes))

    assert_not duplicate.valid?
    assert duplicate.errors.added?(:lensable_type, :taken, value: "Rollover")
  end

  test "rate info is unique per budget" do
    @budget.lenses.create!(lensable: RateInfo.new(currency_codes: [ "EUR" ]))
    duplicate = @budget.lenses.new(lensable: RateInfo.new(currency_codes: [ "GBP" ]))

    assert_not duplicate.valid?
    assert duplicate.errors.added?(:lensable_type, :taken, value: "RateInfo")
  end

  test "plan overview totals mixed currencies in the budget base currency" do
    category = @budget.categories.create!(name: "Euro plan")
    @budget.allocations.create!(category:, amount: 80, currency_code: "EUR", rate: "0.8")

    snapshot = PlanOverview.new.snapshot(budget: @budget)
    assert_equal BigDecimal("400"), snapshot.allocated_amount
    assert_equal BigDecimal("125"), snapshot.used_amount
    assert_equal BigDecimal("275"), snapshot.remaining_amount
    assert_equal 2, snapshot.records.size
  end
end
