require "test_helper"

class ExpenseTest < ActiveSupport::TestCase
  test "defaults occurrence within the budget and inherits source currency" do
    budget = budgets(:active)

    travel_to Date.new(2026, 8, 20) do
      expense = budget.expenses.new(source: sources(:active), amount: 1)

      assert expense.valid?
      assert_equal Date.current, expense.occurred_on
      assert_equal "USD", expense.currency_code
      assert_equal sources(:active).rate, expense.rate
      assert_equal "$", expense.currency_symbol
      assert_equal "US Dollar", expense.currency_name
    end

    travel_to Date.new(2026, 10, 1) do
      expense = budget.expenses.new(source: sources(:active), amount: 1)

      assert expense.valid?
      assert_equal budget.period_to, expense.occurred_on
    end
  end

  test "snapshots the source currency rate" do
    source = budgets(:active).sources.create!(name: "Dong", amount: 266000, currency_code: "VND", rate: "26600")
    expense = budgets(:active).expenses.create!(source: source, amount: 10)

    source.update!(rate: "27000")

    assert_equal BigDecimal("26600"), expense.reload.rate
    assert_equal BigDecimal("10") / BigDecimal("26600"), expense.amount_in_base
  end

  test "converts a purchase through its source into the budget and allocation currencies" do
    budget = budgets(:active)
    source = budget.sources.create!(name: "Rubles", amount: 50_000, currency_code: "RUB", rate: 80)
    allocation = budget.allocations.create!(name: "Thailand", amount: 3_922, currency_code: "THB", rate: 35)
    expense = budget.expenses.new(
      source: source,
      allocation: allocation,
      amount: 1_601_200,
      currency_code: "VND",
      conversion_rate: 320
    )

    assert expense.save_with_source_capacity
    assert_equal BigDecimal("5003.75"), expense.source_amount
    assert_equal "RUB", expense.source_currency_code
    assert_equal BigDecimal("80"), expense.source_rate
    assert_equal BigDecimal("25600"), expense.rate
    assert_equal BigDecimal("62.546875"), expense.amount_in_base
    assert_equal BigDecimal("44996.25"), source.reload.spendable_amount
    assert_equal BigDecimal("2189.140625"), allocation.reload.spent_amount
  end

  test "rejects a cross-currency debit that rounds to zero" do
    expense = budgets(:active).expenses.new(
      source: sources(:active), amount: "0.0001", currency_code: "VND", conversion_rate: 100
    )

    assert_not expense.save_with_source_capacity
    assert expense.errors.added?(:source_amount, :greater_than, value: BigDecimal("0"), count: 0)
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

  test "does not allow a finished allocation on a new expense" do
    allocation = allocations(:active)
    allocation.update!(finished_at: Time.current)

    expense = budgets(:active).expenses.new(source: sources(:active), allocation: allocation, amount: 1)

    assert_not expense.valid?
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
      assert expense.save_with_source_capacity, expense.errors.full_messages.inspect
    end

    assert_equal "Coffee", expense.allocation.name
    assert_equal "coffee", expense.allocation.icon
    assert_equal "coral", expense.allocation.colour
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

  test "does not change recorded monetary facts" do
    expense = expenses(:active)

    assert_not expense.update(amount: 1)
    assert expense.errors.added?(:base, "expense monetary facts cannot be changed")
    assert_equal BigDecimal("125"), expense.reload.amount
  end

  test "deletion restores source capacity" do
    expense = expenses(:active)
    source = expense.source

    assert_difference -> { source.reload.spendable_amount }, expense.source_amount do
      expense.destroy_with_source_lock!
    end
  end
end
