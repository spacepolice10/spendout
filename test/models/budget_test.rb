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
    assert_equal BigDecimal("1"), budget.base_currency.rate
    assert_equal BigDecimal("100"), budget.base_source.amount
  end

  test "rolls back the aggregate when its base source is invalid" do
    budget = build_budget
    budget.source_amount = -1

    assert_no_difference([ "Budget.count", "Currency.count", "Source.count" ]) do
      assert_not budget.save_with_base_source
    end
  end

  test "returns the first source and its currency as the base" do
    budget = budgets(:active)
    source = sources(:active)

    assert_equal currencies(:active_usd), budget.base_currency
    assert_equal source, budget.base_source
  end

  test "summarizes converted active sources and allocations in base currency" do
    budget = budgets(:active)
    euro = budget.currencies.create!(alphabetic_code: "EUR", rate: "1.100000000000")
    euro_source = budget.sources.create!(
      name: "Euros",
      amount: "25.5000",
      currency_code: "EUR",
      icon: "wallet",
      colour: "green"
    )
    euro_allocation = budget.allocations.create!(
      name: "European trip",
      amount: "5.2500",
      currency_code: "EUR",
      icon: "plane",
      colour: "blue"
    )

    assert_equal BigDecimal("1528.3000"), budget.sources_amount_in_base
    assert_equal BigDecimal("305.7750"), budget.allocations_amount_in_base
    assert_equal BigDecimal("1222.5250"), budget.amount_summary

    euro_allocation.update!(deleted_at: Time.current)
    euro_source.update!(deleted_at: Time.current)

    assert_equal BigDecimal("1500.2500"), budget.sources_amount_in_base
    assert_equal BigDecimal("300.0000"), budget.allocations_amount_in_base
    assert_equal BigDecimal("1200.2500"), budget.amount_summary

    euro.update!(rate: "1.200000000000")
    euro_source.update_columns(deleted_at: nil)
    euro_allocation.update_columns(deleted_at: nil)

    assert_equal BigDecimal("1224.5500"), budget.amount_summary
  end

  test "summarizes expenses in base currency and excludes deleted sources" do
    budget = budgets(:active)
    budget.currencies.create!(alphabetic_code: "EUR", rate: "1.100000000000")
    source = budget.sources.create!(
      name: "Euros",
      amount: "25.5000",
      currency_code: "EUR",
      icon: "wallet",
      colour: "green"
    )
    expense = budget.expenses.create!(
      source: source,
      amount: "5.2500",
      occurred_on: budget.period_from
    )

    assert_equal BigDecimal("130.7750"), budget.expenses_amount_in_base
    assert_equal BigDecimal("5.7750"), budget.unallocated_expenses_amount_in_base
    assert_equal BigDecimal("1397.5250"), budget.available_summary

    source.update!(deleted_at: Time.current)

    assert_equal BigDecimal("125.0000"), budget.expenses_amount_in_base
    assert_equal BigDecimal("0"), budget.unallocated_expenses_amount_in_base
    assert_equal BigDecimal("1375.2500"), budget.available_summary
    assert_equal expense, budget.expenses.find(expense.id)
  end

  test "calculates a rolling remainder only during the active period" do
    budget = budgets(:active)

    travel_to Date.new(2026, 8, 19) do
      assert_equal BigDecimal("1200.2500") / 29, budget.todays_remainder

      budget.expenses.create!(
        source: sources(:active),
        allocation: allocations(:active),
        amount: 10,
        occurred_on: Date.current
      )
      assert_equal BigDecimal("1200.2500") / 29, budget.todays_remainder

      budget.expenses.create!(
        source: sources(:active),
        amount: 29,
        occurred_on: Date.current
      )
      assert_equal BigDecimal("1171.2500") / 29, budget.todays_remainder
    end

    travel_to Date.new(2026, 8, 17) do
      assert_nil budget.todays_remainder
    end

    travel_to Date.new(2026, 9, 17) do
      assert_nil budget.todays_remainder
    end
  end

  test "calculates today's remainder as a percentage of the daily target" do
    budget = budgets(:active)

    travel_to budget.period_from do
      assert_equal BigDecimal("100"), budget.todays_remainder_percentage

      budget.expenses.create!(
        source: sources(:active),
        amount: 300,
        occurred_on: Date.current
      )

      assert_in_delta 75, budget.todays_remainder_percentage.to_f, 0.1
    end

    travel_to budget.period_to + 1.day do
      assert_nil budget.todays_remainder_percentage
    end
  end

  test "caps today's remainder by the money actually available in sources" do
    budget = budgets(:active)
    source = sources(:active)

    travel_to Date.new(2026, 8, 19) do
      budget.expenses.create!(
        source: source,
        allocation: allocations(:active),
        amount: source.spendable_amount,
        occurred_on: Date.current
      )

      assert_equal BigDecimal("0"), budget.available_summary
      assert_equal BigDecimal("0"), budget.todays_remainder
      assert_equal BigDecimal("0"), budget.todays_remainder_percentage
    end
  end

  test "counts days until the budget is archived" do
    budget = budgets(:active)

    travel_to Date.new(2026, 8, 19) do
      assert_equal 29, budget.days_until_archived
    end

    travel_to budget.period_to do
      assert_equal 1, budget.days_until_archived
    end

    travel_to budget.period_to + 1.day do
      assert_nil budget.days_until_archived
    end
  end

  private
    def build_budget(period_from: Date.new(2026, 8, 18), duration: nil)
      attributes = { period_from: period_from }
      attributes[:duration] = duration if duration
      users(:one).budgets.new(attributes.merge(currency_code: "USD", source_amount: 100))
    end
end
