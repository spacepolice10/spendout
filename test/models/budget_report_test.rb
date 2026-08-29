require "test_helper"

class BudgetReportTest < ActiveSupport::TestCase
  setup do
    @budget = budgets(:active)
    @source = sources(:active)
    @allocation = allocations(:active)
    @report = @budget.report
  end

  test "summarizes spending by date and category in the budget base currency" do
    other_category = @budget.allocations.create!(
      name: "Coffee", amount: 0, planned: false, currency_code: "USD", icon: "coffee", colour: "coral"
    )
    @budget.expenses.create!(source: @source, allocation: other_category, amount: 25, occurred_on: Date.new(2026, 8, 20))
    @budget.expenses.create!(source: @source, allocation: nil, amount: 10, occurred_on: Date.new(2026, 8, 20))

    assert_equal (@budget.starts_date..@budget.ends_date).count, @report.spending_calendar.size
    assert_equal BigDecimal("125"), @report.spending_calendar.find { |day| day.date == Date.new(2026, 8, 19) }.amount
    assert_equal 4, @report.spending_calendar.find { |day| day.date == Date.new(2026, 8, 19) }.intensity
    assert_equal BigDecimal("35"), @report.spending_calendar.find { |day| day.date == Date.new(2026, 8, 20) }.amount
    assert_equal 0, @report.spending_calendar.find { |day| day.date == Date.new(2026, 8, 18) }.intensity
    assert_equal "Housing", @report.most_expensive_category.name
    assert_equal [ "Housing", "Coffee", "Uncategorized" ], @report.spending_by_category.map(&:name)
    assert_equal 3, @report.spending_by_category.sum(&:expense_count)
  end

  test "summarizes expense metrics over elapsed budget days" do
    travel_to Date.new(2026, 8, 20) do
      assert_equal BigDecimal("125"), @report.total_expenses
      assert_equal BigDecimal("125") / 3, @report.daily_average
      assert_equal expenses(:active), @report.largest_expense
      assert_equal 1, @report.transaction_count
      assert_equal BigDecimal("1200.25"), @report.remaining_general_funds
    end
  end

  test "keeps historical spending from deleted sources and allocations" do
    @source.update!(deleted_at: Time.current)
    @allocation.update!(deleted_at: Time.current)

    assert_equal BigDecimal("125"), @report.total_expenses
    assert_equal @allocation, @report.most_expensive_category.allocation
  end
end
