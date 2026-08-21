require "test_helper"

class BudgetTest < ActiveSupport::TestCase
  test "first source determines base currency" do
    budget = budgets(:active)

    assert_equal sources(:active), budget.base_source
    assert_equal "USD", budget.base_currency_code
    assert_equal "$", budget.base_currency_symbol
  end

  test "creates a budget and base source atomically" do
    budgets(:active).update_columns(period_to: Date.yesterday)
    budget = users(:one).budgets.new(period_from: Date.current, duration: "14_days",
      currency_code: "EUR", source_amount: "100.2500")

    assert_difference([ "Budget.count", "Source.count" ], 1) do
      assert budget.save_with_base_source
    end
    assert_equal "EUR", budget.base_source.currency_code
    assert_equal BigDecimal("100.25"), budget.base_source.amount
  end

  test "allows only one current budget" do
    budget = users(:one).budgets.new(period_from: Date.current, duration: "14_days",
      currency_code: "USD", source_amount: 1)

    assert_not budget.save_with_base_source
    assert_includes budget.errors.full_messages, "An active budget already exists"
  end

  test "base summaries do not combine unrelated currencies without rates" do
    budget = budgets(:active)
    budget.sources.create!(name: "Euro cash", amount: 100, currency_code: "EUR")
    budget.allocations.create!(name: "Euro plan", amount: 50, currency_code: "EUR")

    assert_equal BigDecimal("1500.25"), budget.sources_amount_in_base
    assert_equal BigDecimal("300"), budget.allocations_amount_in_base
  end
end
