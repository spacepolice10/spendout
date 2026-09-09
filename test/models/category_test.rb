require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "is a budget-owned currency-independent classification" do
    category = budgets(:active).categories.new(name: "Coffee")

    assert category.valid?
    assert_equal "wallet", category.icon
    assert_equal "green", category.colour
  end

  test "retiring a category preserves history and retires its live plan and recurrings" do
    category = categories(:active)
    allocation = allocations(:active)
    recurring = category.recurrences.create!(
      budget: category.budget, name: "Rent", amount: 100, currency_code: "USD",
      occurs_on: Date.current, occurrence_period_in_days: 30
    )
    expense = expenses(:active)

    assert_no_difference([ "Category.count", "Allocation.count", "Expense.count", "Recurrence.count" ]) do
      category.retire!
    end

    assert_predicate category.reload, :deleted?
    assert_predicate allocation.reload, :deleted?
    assert_not_predicate recurring.reload, :active?
    assert_equal category, expense.reload.category
  end
end
