require "test_helper"

class BudgetTest < ActiveSupport::TestCase
  test "finds the currency of the most recently created expense" do
    budget = budgets(:active)
    source = sources(:active)
    budget.expenses.create!(source: source, amount: 1, currency_code: "THB", conversion_rate: "0.03")

    assert_equal "THB", budget.last_expense_currency_code
  end

  test "stores its base currency independently of its sources" do
    budget = budgets(:active)

    assert_equal "USD", budget.base_currency_code
    assert_equal "$", budget.base_currency_symbol

    sources(:active).update_column(:currency_code, "EUR")
    assert_equal "USD", budget.reload.base_currency_code
  end

  test "creates a budget without creating a source" do
    budgets(:active).update_columns(period_to: Date.yesterday)
    budget = users(:one).budgets.new(starts_date: Date.current, ends_date: Date.current + 13.days,
      base_currency_code: "EUR")

    assert_difference("Budget.count", 1) do
      assert_no_difference("Source.count") do
        assert budget.save
      end
    end
    assert_equal "EUR", budget.base_currency_code
  end

  test "base currency cannot change after creation" do
    budget = budgets(:active)

    assert_not budget.update(base_currency_code: "EUR")
    assert_includes budget.errors[:base_currency_code], "cannot be changed"
  end

  test "allows only one current budget" do
    budget = users(:one).budgets.new(starts_date: Date.current, ends_date: Date.current + 13.days,
      base_currency_code: "USD")

    assert_not budget.save
    assert_includes budget.errors.full_messages, "An active budget already exists"
  end

  test "planned allocations in other currencies reduce the base currency remainder" do
    budget = budgets(:active)
    budget.sources.create!(name: "Euro cash", amount: 100, currency_code: "EUR", rate: "0.8")
    budget.allocations.create!(name: "Euro plan", amount: 50, currency_code: "EUR", rate: "0.8")

    assert_equal BigDecimal("1625.25"), budget.sources_amount_in_base
    assert_equal BigDecimal("362.5"), budget.allocations_amount_in_base
    assert_equal BigDecimal("1262.75"), budget.amount_summary
  end

  test "source remainder subtracts expenses and only the unspent part of plans" do
    budget = budgets(:active)
    source = sources(:active)

    assert_equal BigDecimal("1200.25"), budget.sources_remainder_in_base

    budget.expenses.create!(source: source, amount: 25, occurred_on: Date.current)

    assert_equal BigDecimal("1175.25"), budget.sources_remainder_in_base
  end

  test "finishing a plan releases its unspent reservation" do
    budget = budgets(:active)
    allocation = allocations(:active)

    assert_equal BigDecimal("1200.25"), budget.sources_remainder_in_base

    allocation.update!(finished_at: Time.current)

    assert_equal BigDecimal("1375.25"), budget.sources_remainder_in_base
    assert_equal BigDecimal("125"), budget.allocations_amount_in_base
    assert_equal BigDecimal("1375.25"), budget.amount_summary
  end

  test "today's remainder rolls unused daily spending forward" do
    budget = budgets(:active)
    source = sources(:active)
    budget.expenses.delete_all
    budget.allocations.delete_all
    budget.sources.where.not(id: source.id).delete_all
    source.update!(amount: 99_000)
    budget.update_columns(period_from: Date.new(2026, 8, 1), period_to: Date.new(2026, 8, 30))

    travel_to Date.new(2026, 8, 1) do
      budget.expenses.create!(source: source, amount: 1_500, occurred_on: Date.current)

      assert_equal BigDecimal("1800"), budget.todays_remainder
      assert_in_delta 54.55, budget.todays_remainder_percentage.to_f, 0.01
    end

    travel_to Date.new(2026, 8, 2) do
      assert_equal BigDecimal("5100"), budget.todays_remainder
      assert_equal BigDecimal("100"), budget.todays_remainder_percentage
      budget.expenses.create!(source: source, amount: 10_000, occurred_on: Date.current)
      assert_equal BigDecimal("0"), budget.todays_remainder_percentage
    end

    travel_to Date.new(2026, 8, 3) do
      assert_equal BigDecimal("-1600"), budget.todays_remainder
      assert_equal BigDecimal("0"), budget.todays_remainder_percentage
    end
  end

  test "planned category spending does not consume the daily remainder" do
    budget = budgets(:active)
    source = sources(:active)
    budget.expenses.delete_all
    budget.allocations.delete_all
    budget.sources.where.not(id: source.id).delete_all
    source.update!(amount: 3_300)
    budget.update_columns(period_from: Date.new(2026, 8, 1), period_to: Date.new(2026, 8, 30))

    travel_to Date.new(2026, 8, 1) do
      planned = budget.allocations.create!(
        name: "Rent",
        amount: 300,
        currency_code: "USD",
        rate: 1,
        planned: true
      )

      assert_equal BigDecimal("100"), budget.todays_remainder
      assert_equal BigDecimal("100"), budget.todays_remainder_percentage

      budget.expenses.create!(
        source: source,
        allocation: planned,
        amount: 50,
        occurred_on: Date.current
      )

      assert_equal BigDecimal("100"), budget.todays_remainder
      assert_equal BigDecimal("100"), budget.todays_remainder_percentage

      budget.expenses.create!(source: source, amount: 50, occurred_on: Date.current)

      assert_equal BigDecimal("50"), budget.todays_remainder
      assert_equal BigDecimal("50"), budget.todays_remainder_percentage
    end
  end
end
