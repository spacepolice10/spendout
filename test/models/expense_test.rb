require "test_helper"

class ExpenseTest < ActiveSupport::TestCase
  test "defaults occurrence within the budget and inherits source currency" do
    budget = budgets(:active)

    travel_to Date.new(2026, 8, 20) do
      expense = budget.expenses.new(source: sources(:active), category: categories(:active), amount: 1)

      assert expense.valid?
      assert_equal Date.current, expense.occurred_on
      assert_equal "USD", expense.currency_code
      assert_equal "$", expense.currency_symbol
      assert_equal "US Dollar", expense.currency_name
    end

    travel_to Date.new(2026, 10, 1) do
      expense = budget.expenses.new(source: sources(:active), category: categories(:active), amount: 1)

      assert expense.valid?
      assert_equal budget.period_to, expense.occurred_on
    end
  end

  test "requires a category" do
    expense = budgets(:active).expenses.new(source: sources(:active), amount: 1)

    assert_not expense.valid?
    assert expense.errors.added?(:category, :blank)
  end

  test "uses the source currency rate" do
    budget = budgets(:active)
    source = budget.sources.create!(name: "Dong", amount: 266000, currency_code: "VND", rate: "26600")
    expense = budget.expenses.create!(source:, category: categories(:active), amount: 10)

    assert_equal BigDecimal("10") / BigDecimal("26600"), expense.reload.amount_in_base_currency
  end

  test "converts a purchase through its source while category stays currency independent" do
    budget = budgets(:active)
    source = budget.sources.create!(name: "Rubles", amount: 50_000, currency_code: "RUB", rate: 80)
    category = budget.categories.create!(name: "Thailand", icon: "plane", colour: "blue")
    allocation = budget.allocations.create!(category:, amount: 3_922, currency_code: "THB", rate: 35)
    expense = budget.expenses.new(
      source:, category:, amount: 1_601_200, currency_code: "VND", conversion_rate: 320
    )

    assert expense.save_with_source_capacity
    assert_equal BigDecimal("5003.75"), expense.source_amount
    assert_equal BigDecimal("62.546875"), expense.amount_in_base_currency
    assert_equal BigDecimal("44996.25"), source.reload.spendable_amount
    assert_equal BigDecimal("2189.140625"), allocation.reload.used_amount
  end

  test "rejects a cross-currency debit that rounds to zero" do
    expense = budgets(:active).expenses.new(
      source: sources(:active), category: categories(:active), amount: "0.0001",
      currency_code: "VND", conversion_rate: 100
    )

    assert_not expense.save_with_source_capacity
    assert expense.errors.added?(:source_amount, :greater_than, value: BigDecimal("0"), count: 0)
  end

  test "requires a positive amount and an occurrence within the budget" do
    expense = budgets(:active).expenses.new(
      source: sources(:active), category: categories(:active), amount: 0,
      occurred_on: Date.new(2026, 8, 17)
    )

    assert_not expense.valid?
    assert expense.errors.added?(:amount, :greater_than, value: 0, count: 0)
    assert expense.errors.added?(:occurred_on, "must be within the budget period")
  end

  test "requires active associations from the same budget" do
    budget = budgets(:active)
    expense = budget.expenses.new(source: sources(:other), category: categories(:other), amount: 1)

    assert_not expense.valid?
    assert expense.errors.added?(:source, "must belong to this budget")
    assert expense.errors.added?(:category, :wrong_budget)

    expense.assign_attributes(source: sources(:active), category: categories(:active))
    assert expense.valid?

    categories(:active).update_column(:deleted_at, Time.current)
    assert_not expense.valid?
    assert expense.errors.added?(:category, :inactive)
  end

  test "a finished plan does not block expenses in its category" do
    allocation = allocations(:active)
    allocation.update!(finished_at: Time.current)
    expense = budgets(:active).expenses.new(
      source: sources(:active), category: allocation.category, amount: 1
    )

    assert expense.valid?
  end

  test "rejects cumulative spending beyond source capacity" do
    source = sources(:active)
    expense = source.budget.expenses.new(source:, category: categories(:active), amount: "1375.2501")

    assert_not expense.save_with_source_capacity
    assert expense.errors.added?(:amount, "must be less than or equal to 1375.25")

    expense.amount = "1375.2500"
    assert expense.save_with_source_capacity
    assert_equal BigDecimal("0"), source.spendable_amount
  end

  test "builds a new category as part of saving" do
    expense = budgets(:active).expenses.new(
      source: sources(:active), amount: 5, category_name_to_create: "Coffee"
    )

    assert_difference([ "Expense.count", "Category.count" ], 1) do
      assert expense.save_with_source_capacity, expense.errors.full_messages.inspect
    end

    assert_equal "Coffee", expense.category.name
    assert_equal "coffee", expense.category.icon
    assert_equal "coral", expense.category.colour
    assert_nil expense.category.allocation
  end

  test "rolls back a new category when the expense cannot be saved" do
    expense = budgets(:active).expenses.new(
      source: sources(:active), amount: 2000, category_name_to_create: "Coffee"
    )

    assert_no_difference([ "Expense.count", "Category.count" ]) do
      assert_not expense.save_with_source_capacity
    end
  end

  test "historical expense remains attached to soft-deleted source and category" do
    budget = budgets(:active)
    source = budget.sources.create!(name: "Cash", amount: 100, currency_code: "USD")
    category = budget.categories.create!(name: "Pocket money")
    expense = budget.expenses.create!(source:, category:, amount: 10)

    source.update!(deleted_at: Time.current)
    category.update!(deleted_at: Time.current)

    assert_equal source, expense.reload.source
    assert_equal category, expense.category
  end

  test "deletion restores source capacity" do
    expense = expenses(:active)
    source = expense.source

    assert_difference -> { source.reload.spendable_amount }, expense.source_amount do
      expense.destroy_with_source_lock!
    end
  end
end
