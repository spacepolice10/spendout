require "test_helper"

class RecurrenceTest < ActiveSupport::TestCase
  test "records a normal categorized expense and advances by its day interval" do
    budget = budgets(:active)
    item = budget.recurrences.create!(
      name: "Internet", category: categories(:active), amount: 30, currency_code: "USD",
      occurs_on: Date.new(2026, 8, 20), occurrence_period_in_days: 30
    )
    expense = budget.expenses.create!(
      source: sources(:active), category: item.category, amount: 30,
      occurred_on: item.occurs_on
    )

    assert_difference("RecurringOccurrence.count", 1) { item.record!(expense) }
    assert_equal Date.new(2026, 9, 19), item.reload.occurs_on
    assert_equal expense, item.expenses.first
  end

  test "requires a category from its budget and a positive interval" do
    item = budgets(:active).recurrences.new(
      name: "Wrong", category: categories(:other), amount: 10, currency_code: "USD",
      occurs_on: Date.current, occurrence_period_in_days: 0
    )

    assert_not item.valid?
    assert item.errors.added?(:category, :wrong_budget)
    assert item.errors.added?(:occurrence_period_in_days, :greater_than, value: 0, count: 0)
  end

  test "a budget destroys recurring links before their historical expenses" do
    budget = budgets(:archived)
    item = budget.recurrences.create!(
      name: "Museum membership", category: categories(:archived), amount: 50,
      currency_code: "EUR", occurs_on: Date.new(2026, 6, 3), occurrence_period_in_days: 30
    )
    item.occurrences.create!(expense: expenses(:archived), due_on: item.occurs_on)

    assert_difference("Budget.count", -1) { budget.destroy! }
  end
end
