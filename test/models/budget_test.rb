require "test_helper"

class BudgetTest < ActiveSupport::TestCase
  test "stores its base currency independently of its first source" do
    budget = budgets(:active)

    assert_equal sources(:active), budget.base_source
    assert_equal "USD", budget.base_currency_code
    assert_equal "$", budget.base_currency_symbol

    sources(:active).update_column(:currency_code, "EUR")
    assert_equal "USD", budget.reload.base_currency_code
  end

  test "creates a budget without creating a source" do
    budgets(:active).update_columns(period_to: Date.yesterday)
    budget = users(:one).budgets.new(period_from: Date.current, duration: "14_days",
      base_currency_code: "EUR")

    assert_difference("Budget.count", 1) do
      assert_no_difference("Source.count") do
        assert budget.save
      end
    end
    assert_equal "EUR", budget.base_currency_code
    assert_nil budget.base_source
  end

  test "base currency cannot change after creation" do
    budget = budgets(:active)

    assert_not budget.update(base_currency_code: "EUR")
    assert_includes budget.errors[:base_currency_code], "cannot be changed"
  end

  test "allows only one current budget" do
    budget = users(:one).budgets.new(period_from: Date.current, duration: "14_days",
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

  test "today's remainder rolls unused daily spending forward" do
    budget = budgets(:active)
    budget.expenses.delete_all
    budget.allocations.delete_all
    budget.sources.where.not(id: budget.base_source.id).delete_all
    budget.base_source.update!(amount: 99_000)
    budget.update_columns(period_from: Date.new(2026, 8, 1), period_to: Date.new(2026, 8, 30))

    travel_to Date.new(2026, 8, 1) do
      budget.expenses.create!(source: budget.base_source, amount: 1_500, occurred_on: Date.current)

      assert_equal BigDecimal("1800"), budget.todays_remainder
      assert_in_delta 54.55, budget.todays_remainder_percentage.to_f, 0.01
    end

    travel_to Date.new(2026, 8, 2) do
      assert_equal BigDecimal("5100"), budget.todays_remainder
      budget.expenses.create!(source: budget.base_source, amount: 10_000, occurred_on: Date.current)
    end

    travel_to Date.new(2026, 8, 3) do
      assert_equal BigDecimal("-1600"), budget.todays_remainder
      assert_equal BigDecimal("0"), budget.todays_remainder_percentage
    end
  end
end
