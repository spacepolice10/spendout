require "test_helper"

class BudgetTest < ActiveSupport::TestCase
  test "calculates exact inclusive durations" do
    fourteen_days = build_budget(period_from: Date.new(2026, 8, 18), duration: "14_days")
    thirty_days = build_budget(period_from: Date.new(2026, 8, 18), duration: "30_days")

    assert fourteen_days.save_with_base_source
    assert_equal Date.new(2026, 8, 31), fourteen_days.period_to
    assert thirty_days.save_with_base_source
    assert_equal Date.new(2026, 9, 16), thirty_days.period_to
  end

  test "defaults to thirty days" do
    budget = build_budget(period_from: Date.new(2026, 2, 20))

    assert budget.save_with_base_source
    assert_equal "30_days", budget.duration
    assert_equal Date.new(2026, 3, 21), budget.period_to
  end

  test "does not recalculate a persisted period from the virtual default" do
    budget = budgets(:archived)
    original_period_to = budget.period_to

    budget.save!

    assert_equal original_period_to, budget.reload.period_to
  end

  test "derives compact names across months and years" do
    same_month = build_budget(period_from: Date.new(2026, 8, 1), duration: "14_days")
    next_month = build_budget(period_from: Date.new(2026, 8, 18), duration: "30_days")
    next_year = build_budget(period_from: Date.new(2026, 12, 20), duration: "30_days")
    [ same_month, next_month, next_year ].each(&:valid?)

    assert_equal "Aug 1 – 14, 2026", same_month.name
    assert_equal "Aug 18 – Sep 16, 2026", next_month.name
    assert_equal "Dec 20, 2026 – Jan 18, 2027", next_year.name
  end

  test "is archived only after its end date" do
    travel_to Date.new(2026, 8, 18) do
      assert_not Budget.new(period_to: Date.current).archived?
      assert Budget.new(period_to: Date.yesterday).archived?
    end
  end

  test "rejects unsupported durations" do
    budget = build_budget(duration: "month")

    assert_not budget.valid?
    assert budget.errors.added?(:duration, :inclusion, value: "month")
  end

  test "requires creation currency and source amount" do
    budget = users(:one).budgets.new(period_from: Date.current)

    assert_not budget.valid?
    assert budget.errors.added?(:currency_code, :inclusion, value: nil)
    assert budget.errors.added?(:source_amount, :not_a_number, value: nil)
  end

  test "cannot save without its base currency and source" do
    budget = build_budget

    assert_not budget.save
    assert budget.errors.added?(:currencies, :blank)
    assert budget.errors.added?(:sources, :blank)
  end

  test "saves the complete base aggregate atomically" do
    budget = build_budget

    assert_difference([ "Budget.count", "Currency.count", "Source.count" ], 1) do
      assert budget.save_with_base_source
    end

    assert_equal "USD", budget.base_currency.alphabetic_code
    assert_equal BigDecimal("100"), budget.base_source.amount
  end

  test "rolls back the aggregate when its base source is invalid" do
    budget = build_budget
    budget.source_amount = -1

    assert_no_difference([ "Budget.count", "Currency.count", "Source.count" ]) do
      assert_not budget.save_with_base_source
    end
  end

  test "returns the base source and currency even when the source is deleted" do
    budget = budgets(:active)
    source = sources(:active)
    source.update!(deleted_at: Time.current)

    assert_equal currencies(:active_usd), budget.base_currency
    assert_equal source, budget.base_source
  end

  private
    def build_budget(period_from: Date.new(2026, 8, 18), duration: nil)
      attributes = { period_from: period_from }
      attributes[:duration] = duration if duration
      users(:one).budgets.new(attributes.merge(currency_code: "USD", source_amount: 100))
    end
end
