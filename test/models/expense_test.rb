require "test_helper"

class ExpenseTest < ActiveSupport::TestCase
  test "defaults occurrence within the budget and inherits source currency" do
    budget = budgets(:active)

    travel_to Date.new(2026, 8, 20) do
      expense = budget.expenses.new(source: sources(:active), amount: 1)

      assert expense.valid?
      assert_equal Date.current, expense.occurred_on
      assert_equal "USD", expense.currency_code
      assert_equal "$", expense.currency_symbol
      assert_equal "US Dollar", expense.currency_name
    end

    travel_to Date.new(2026, 10, 1) do
      expense = budget.expenses.new(source: sources(:active), amount: 1)

      assert expense.valid?
      assert_equal budget.period_to, expense.occurred_on
    end
  end

  test "requires a positive amount and an occurrence within the budget" do
    expense = budgets(:active).expenses.new(
      source: sources(:active),
      amount: 0,
      occurred_on: Date.new(2026, 8, 17)
    )

    assert_not expense.valid?
    assert expense.errors.added?(:amount, :greater_than, value: 0, count: 0)
    assert expense.errors.added?(:occurred_on, "must be within the budget period")
  end

  test "allows no allocation and limits notes to 200 characters" do
    expense = budgets(:active).expenses.new(
      source: sources(:active),
      amount: 1,
      allocation: nil,
      note: "n" * 200
    )

    assert expense.valid?

    expense.note = "n" * 201
    assert_not expense.valid?
    assert expense.errors.added?(:note, :too_long, count: 200)
  end

  test "requires active associations from the budget but allows any budget allocation" do
    budget = budgets(:active)
    expense = budget.expenses.new(source: sources(:other), allocation: allocations(:other), amount: 1)

    assert_not expense.valid?
    assert expense.errors.added?(:source, "must belong to this budget")
    assert expense.errors.added?(:allocation, "must belong to this budget")

    second_source = budget.sources.create!(
      name: "Cash",
      amount: 100,
      currency_code: "USD",
      icon: "cash-banknote",
      colour: "green"
    )
    expense.source = second_source
    expense.allocation = allocations(:active)

    assert expense.valid?

    second_source.update_column(:deleted_at, Time.current)
    allocations(:active).update_column(:deleted_at, Time.current)
    expense.source.reload
    expense.allocation.reload

    assert_not expense.valid?
    assert expense.errors.added?(:source, "must be active")
    assert expense.errors.added?(:allocation, "must be active")
  end

  test "rejects cumulative spending beyond source capacity" do
    source = sources(:active)
    expense = source.budget.expenses.new(source: source, amount: "1375.2501")

    assert_not expense.save_with_source_capacity
    assert expense.errors.added?(:amount, "must be less than or equal to 1375.25")
    assert_not expense.persisted?

    expense.amount = "1375.2500"
    assert expense.save_with_source_capacity
    assert_equal BigDecimal("1500.2500"), source.expenses.sum(:amount)
    assert_equal BigDecimal("0"), source.spendable_amount
  end

  test "builds a new unplanned category as part of saving" do
    budget = budgets(:active)
    expense = budget.expenses.new(
      source: sources(:active),
      allocation: allocations(:active),
      amount: 5,
      category_name_to_create: "Coffee"
    )

    assert_difference([ "Expense.count", "Allocation.count" ], 1) do
      assert expense.save_with_source_capacity
    end

    assert_equal "Coffee", expense.allocation.name
    assert_not expense.allocation.planned?
  end

  test "rolls back a new category when the expense cannot be saved" do
    budget = budgets(:active)
    expense = budget.expenses.new(
      source: sources(:active),
      amount: 2000,
      category_name_to_create: "Coffee"
    )

    assert_no_difference([ "Expense.count", "Allocation.count" ]) do
      assert_not expense.save_with_source_capacity
    end
  end

  test "historical expense remains attached to soft-deleted associations" do
    budget = budgets(:active)
    source = budget.sources.create!(
      name: "Cash",
      amount: 100,
      currency_code: "USD",
      icon: "cash-banknote",
      colour: "green"
    )
    allocation = budget.allocations.create!(
      name: "Pocket money",
      amount: 50,
      currency_code: "USD",
      icon: "wallet",
      colour: "green"
    )
    expense = budget.expenses.create!(source: source, allocation: allocation, amount: 10)

    allocation.update!(deleted_at: Time.current)
    source.update!(deleted_at: Time.current)

    assert_equal source, expense.reload.source
    assert_equal allocation, expense.allocation
  end

  test "deletion restores source capacity" do
    expense = expenses(:active)
    source = expense.source

    assert_difference -> { source.reload.spendable_amount }, expense.amount do
      expense.destroy_with_source_lock!
    end
  end
end
