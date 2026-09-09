require "test_helper"

class IncomeTest < ActiveSupport::TestCase
  test "adds a precise amount to its destination source" do
    budget = budgets(:active)
    source = sources(:active)
    opening = source.spendable_amount
    income = budget.incomes.create!(
      source:, source_name: "Salary", amount: "80", currency_code: "EUR",
      conversion_rate: "0.8", occurred_on: Date.current
    )

    assert_equal BigDecimal("100"), income.source_amount
    assert_equal opening + BigDecimal("100"), source.reload.spendable_amount
    assert_equal BigDecimal("100"), income.amount_in_base_currency
  end

  test "is immutable and requires an active source from the same budget" do
    income = budgets(:active).incomes.new(
      source: sources(:other), source_name: "Salary", amount: 10,
      currency_code: "VND", occurred_on: Date.current
    )

    assert_not income.valid?
    assert income.errors.added?(:source, :wrong_budget)

    source = sources(:active)
    income.assign_attributes(source:, currency_code: "USD")
    assert income.save
    assert_not income.update(amount: 20)

    source.update!(deleted_at: Time.current)
    another = budgets(:active).incomes.new(
      source:, source_name: "Gift", amount: 1, currency_code: "USD", occurred_on: Date.current
    )
    assert_not another.valid?
    assert another.errors.added?(:source, :inactive)
  end

  test "cannot be deleted when doing so would overdraw its wallet" do
    budget = budgets(:active)
    source = budget.sources.create!(name: "Income-only", amount: 0, currency_code: "USD")
    income = budget.incomes.create!(
      source:, source_name: "Client", amount: 100, currency_code: "USD", occurred_on: Date.current
    )
    category = budget.categories.create!(name: "Spent")
    budget.expenses.create!(source:, category:, amount: 50, occurred_on: Date.current)

    assert_not income.destroy_with_source_lock
    assert income.errors.added?(:base, :would_overdraw)
    assert income.persisted?
  end
end
