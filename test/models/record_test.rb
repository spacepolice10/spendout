require "test_helper"

class RecordTest < ActiveSupport::TestCase
  setup { @budget = budgets(:active) }

  test "creating an expense or income creates a record" do
    assert_difference("Record.count", 1) do
      expense = @budget.expenses.create!(source: sources(:active), category: categories(:active), amount: 9,
        occurred_on: Date.new(2026, 8, 20))
      assert expense.record.expense?
      assert_equal expense, expense.record.recordable
      assert_equal @budget, expense.record.budget
      assert_equal Date.new(2026, 8, 20), expense.record.occurred_on
    end

    assert_difference("Record.count", 1) do
      income = @budget.incomes.create!(source: sources(:active), source_name: "Salary", amount: 40,
        currency_code: "USD", occurred_on: Date.new(2026, 8, 21))
      assert income.record.income?
      assert_equal income, income.record.recordable
    end
  end

  test "destroying an expense or income removes its record" do
    expense = @budget.expenses.create!(source: sources(:active), category: categories(:active), amount: 3)
    income = @budget.incomes.create!(source: sources(:active), source_name: "Gift", amount: 10,
      currency_code: "USD", occurred_on: Date.current)

    assert_difference("Record.count", -1) { expense.destroy_with_source_lock! }
    assert_difference("Record.count", -1) { income.destroy_with_source_lock }
  end

  test "fixture expenses are wrapped as records" do
    record = records(:active)

    assert record.expense?
    assert_equal expenses(:active), record.expense
    assert_equal BigDecimal("125"), record.amount_in_base_currency
  end
end
